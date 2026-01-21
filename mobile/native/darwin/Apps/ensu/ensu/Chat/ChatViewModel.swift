import Foundation
import EnteCore

struct ChatAttachment: Identifiable, Equatable {
    enum Kind {
        case image
        case document
    }

    let id: UUID
    let name: String
    let size: Int64
    let kind: Kind
    let url: URL?
    var isUploading: Bool

    init(id: UUID = UUID(), name: String, size: Int64, kind: Kind, url: URL? = nil, isUploading: Bool = false) {
        self.id = id
        self.name = name
        self.size = size
        self.kind = kind
        self.url = url
        self.isUploading = isUploading
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var iconName: String {
        switch kind {
        case .image:
            return "photo"
        case .document:
            return "doc.text"
        }
    }
}

struct AttachmentDownloadItem: Identifiable, Equatable {
    enum Status {
        case queued
        case downloading
        case completed
        case failed
        case canceled
    }

    let id: String
    let sessionId: UUID
    let name: String
    let size: Int64
    var status: Status
    var errorMessage: String? = nil

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ChatMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id: UUID
    var role: Role
    var text: String
    var timestamp: Date
    var attachments: [ChatAttachment]
    var isInterrupted: Bool
    var tokensPerSecond: Double?
    var branchIndex: Int
    var branchCount: Int

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        timestamp: Date = Date(),
        attachments: [ChatAttachment] = [],
        isInterrupted: Bool = false,
        tokensPerSecond: Double? = nil,
        branchIndex: Int = 1,
        branchCount: Int = 1
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.attachments = attachments
        self.isInterrupted = isInterrupted
        self.tokensPerSecond = tokensPerSecond
        self.branchIndex = branchIndex
        self.branchCount = branchCount
    }
}

struct ChatSession: Identifiable, Equatable {
    let id: UUID
    var title: String
    var lastMessage: String
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, lastMessage: String, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
    }
}

struct DownloadToastState: Identifiable, Equatable {
    enum Phase {
        case downloading
        case loading
        case complete
        case errorDownload
        case errorLoad
    }

    let id = UUID()
    var phase: Phase
    var percent: Int
    var status: String
    var offerRetryDownload: Bool
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var sessions: [ChatSession]
    @Published var currentSessionId: UUID?
    @Published var messages: [ChatMessage]
    @Published var streamingResponse: String = ""
    @Published var streamingParentId: UUID? = nil

    var displayedStreamingResponse: String {
        guard let activeSession = activeGenerationSessionId,
              activeSession == currentSessionId,
              activeGenerationId != nil else {
            return ""
        }
        return streamingResponse
    }

    var displayedStreamingParentId: UUID? {
        guard let activeSession = activeGenerationSessionId,
              activeSession == currentSessionId,
              activeGenerationId != nil else {
            return nil
        }
        return streamingParentId
    }
    @Published var isGenerating: Bool = false
    @Published var isDownloading: Bool = false
    @Published var isProcessingAttachments: Bool = false
    @Published var draftText: String = ""
    @Published var draftAttachments: [ChatAttachment] = []
    @Published var editingMessageId: UUID?
    @Published var downloadToast: DownloadToastState?
    @Published var attachmentDownloads: [AttachmentDownloadItem] = []
    @Published var currentSessionMissingAttachments: [AttachmentDownloadItem] = []
    @Published var syncErrorMessage: String?

    private let provider: InferenceRsProvider
    private let chatDb: LlmChatDb
    private let syncEngine: LlmChatSync
    private let attachmentsDir: URL
    private let modelSettings = ModelSettingsStore.shared

    private var messageStore: [UUID: [MessageNode]] = [:]
    private var branchSelections: [UUID: [String: UUID]] = [:]
    private let rootId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    private var generationTask: Task<Void, Never>?
    private var stopRequested = false
    private var activeGenerationId: UUID?
    private var activeGenerationSessionId: UUID?
    private var pendingSyncRequested = false
    private var pendingSyncShowErrors = false

    private var attachmentDownloadQueue: [String] = []
    private var attachmentDownloadTasks: [String: Task<Void, Never>] = [:]
    private let maxAttachmentDownloads = 2

    init() {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        // LLM model files.
        let llmDir = baseDir.appendingPathComponent("llm", isDirectory: true)
        let provider = InferenceRsProvider(modelDir: llmDir)

        // Chat DB + attachments.
        let dbDir = baseDir.appendingPathComponent("llmchat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true, attributes: nil)
        let attachmentsDir = dbDir.appendingPathComponent("chat_attachments", isDirectory: true)
        try? FileManager.default.createDirectory(at: attachmentsDir, withIntermediateDirectories: true, attributes: nil)

        let key = CredentialStore.shared.getOrCreateChatDbKey()
        let mainDbPath = dbDir.appendingPathComponent("llmchat.db").path
        let attachmentsDbPath = dbDir.appendingPathComponent("llmchat_attachments.db").path

        let chatDb: LlmChatDb
        do {
            chatDb = try LlmChatDb.open(mainDbPath: mainDbPath, attachmentsDbPath: attachmentsDbPath, key: key)
        } catch {
            fatalError("Failed to open chat DB: \(error)")
        }

        let syncMetaDir = dbDir.appendingPathComponent("sync_meta", isDirectory: true)
        try? FileManager.default.createDirectory(at: syncMetaDir, withIntermediateDirectories: true, attributes: nil)
        let encryptedAttachmentsDir = dbDir.appendingPathComponent("chat_attachments_encrypted", isDirectory: true)
        try? FileManager.default.createDirectory(at: encryptedAttachmentsDir, withIntermediateDirectories: true, attributes: nil)

        let syncEngine: LlmChatSync
        do {
            syncEngine = try LlmChatSync.open(
                mainDbPath: mainDbPath,
                attachmentsDbPath: attachmentsDbPath,
                dbKey: key,
                attachmentsDir: encryptedAttachmentsDir.path,
                metaDir: syncMetaDir.path,
                plaintextDir: attachmentsDir.path
            )
        } catch {
            fatalError("Failed to open chat sync: \(error)")
        }

        // Load sessions/messages.
        let loaded = (try? chatDb.listSessions()) ?? []
        let sessions: [ChatSession] = loaded.compactMap { session in
            guard let id = UUID(uuidString: session.uuid) else { return nil }
            let lastMessage = (try? chatDb.getMessages(sessionUuid: session.uuid))?.last?.text ?? ""
            return ChatSession(
                id: id,
                title: session.title,
                lastMessage: lastMessage,
                updatedAt: Date(timeIntervalSince1970: Double(session.updatedAtUs) / 1_000_000.0)
            )
        }

        // Stored properties.
        self.provider = provider
        self.chatDb = chatDb
        self.syncEngine = syncEngine
        self.attachmentsDir = attachmentsDir

        self.sessions = sessions
        self.currentSessionId = sessions.first?.id
        self.messages = []

        for session in sessions {
            self.messageStore[session.id] = []
            self.branchSelections[session.id] = [:]
        }

        if let current = self.currentSessionId {
            loadMessagesFromDb(for: current)
            rebuildMessages(for: current)
            queueMissingAttachments(for: current)
        } else {
            refreshAttachmentDownloadState()
        }
    }

    var currentSession: ChatSession? {
        guard let currentSessionId else { return nil }
        return sessions.first { $0.id == currentSessionId }
    }

    var isAttachmentDownloadBlocked: Bool {
        !currentSessionMissingAttachments.isEmpty
    }

    var attachmentDownloadProgress: Double? {
        let active = attachmentDownloads.filter { $0.status != .canceled }
        let total = active.count
        guard total > 0 else { return nil }
        guard active.contains(where: { $0.status == .queued || $0.status == .downloading || $0.status == .failed }) else {
            return nil
        }
        let completed = active.filter { $0.status == .completed }.count
        return Double(completed) / Double(total)
    }

    var attachmentDownloadSummary: (completed: Int, total: Int)? {
        let active = attachmentDownloads.filter { $0.status != .canceled }
        let total = active.count
        guard total > 0 else { return nil }
        guard active.contains(where: { $0.status == .queued || $0.status == .downloading || $0.status == .failed }) else {
            return nil
        }
        let completed = active.filter { $0.status == .completed }.count
        return (completed, total)
    }

    func sessionTitle(for sessionId: UUID) -> String {
        sessions.first { $0.id == sessionId }?.title ?? "Chat"
    }

    func startNewSession() {
        generationTask?.cancel()
        provider.stopGeneration()
        stopRequested = false
        activeGenerationId = nil
        activeGenerationSessionId = nil
        isGenerating = false
        isDownloading = false
        streamingResponse = ""
        streamingParentId = nil
        downloadToast = nil
        draftText = ""
        draftAttachments = []
        editingMessageId = nil

        currentSessionId = nil
        messages = []
        refreshAttachmentDownloadState()
    }

    func selectSession(_ session: ChatSession) {
        generationTask?.cancel()
        provider.stopGeneration()
        stopRequested = false
        activeGenerationId = nil
        activeGenerationSessionId = nil
        isGenerating = false
        isDownloading = false
        streamingResponse = ""
        streamingParentId = nil
        downloadToast = nil
        currentSessionId = session.id
        loadMessagesFromDb(for: session.id)
        rebuildMessages(for: session.id)
        queueMissingAttachments(for: session.id)
    }

    func deleteSession(_ session: ChatSession) {
        if currentSessionId == session.id {
            generationTask?.cancel()
            provider.stopGeneration()
            stopRequested = false
            activeGenerationId = nil
            activeGenerationSessionId = nil
            isGenerating = false
            isDownloading = false
            streamingResponse = ""
            streamingParentId = nil
            downloadToast = nil
        }
        try? chatDb.deleteSession(uuid: session.id.uuidString)

        sessions.removeAll { $0.id == session.id }
        messageStore[session.id] = nil
        branchSelections[session.id] = nil
        purgeAttachmentDownloads(for: session.id)
        if currentSessionId == session.id {
            currentSessionId = sessions.first?.id
            if let next = currentSessionId {
                loadMessagesFromDb(for: next)
                rebuildMessages(for: next)
                queueMissingAttachments(for: next)
            } else {
                messages = []
                refreshAttachmentDownloadState()
            }
        }
        syncNow()
    }

    func syncNow(showErrors: Bool = true) {
        if isGenerating {
            pendingSyncRequested = true
            pendingSyncShowErrors = pendingSyncShowErrors || showErrors
            return
        }

        let shouldSync = pendingSyncRequested || showErrors
        let shouldShowErrors = pendingSyncShowErrors || showErrors
        pendingSyncRequested = false
        pendingSyncShowErrors = false
        guard shouldSync else { return }
        performSync(showErrors: shouldShowErrors)
    }

    private func performSync(showErrors: Bool) {
        guard let auth = buildSyncAuth() else {
            if showErrors {
                syncErrorMessage = "Sync failed: Sign in to sync"
            }
            return
        }

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                _ = try self.syncEngine.sync(auth: auth)
                await MainActor.run {
                    self.reloadFromDb()
                }
            } catch {
                let message = syncErrorMessage(from: error)
                await MainActor.run {
                    if showErrors {
                        self.syncErrorMessage = "Sync failed: \(message)"
                    }
                }
            }
        }
    }

    func beginEditing(message: ChatMessage) {
        guard message.role == .user else { return }
        editingMessageId = message.id
        draftText = message.text
        draftAttachments = message.attachments
    }

    func cancelEditing() {
        editingMessageId = nil
        draftText = ""
        draftAttachments = []
    }

    func addImageAttachment(data: Data, fileName: String?) {
        guard !isGenerating && !isDownloading && !isAttachmentDownloadBlocked else { return }
        isProcessingAttachments = true

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let id = UUID()
                let url = try self.writeAttachment(data: data, attachmentId: id)
                let attachment = ChatAttachment(
                    id: id,
                    name: fileName ?? "photo.jpg",
                    size: Int64(data.count),
                    kind: .image,
                    url: url,
                    isUploading: false
                )
                await MainActor.run {
                    self.draftAttachments.append(attachment)
                    self.isProcessingAttachments = false
                }
            } catch {
                await MainActor.run { self.isProcessingAttachments = false }
            }
        }
    }

    func addDocumentAttachment(url: URL) {
        guard !isGenerating && !isDownloading && !isAttachmentDownloadBlocked else { return }
        isProcessingAttachments = true

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let id = UUID()
                let storedUrl = try self.copyAttachment(from: url, attachmentId: id)
                let size = (try? FileManager.default.attributesOfItem(atPath: storedUrl.path)[.size] as? NSNumber)?.int64Value ?? 0
                let attachment = ChatAttachment(
                    id: id,
                    name: url.lastPathComponent,
                    size: size,
                    kind: .document,
                    url: storedUrl,
                    isUploading: false
                )
                await MainActor.run {
                    self.draftAttachments.append(attachment)
                    self.isProcessingAttachments = false
                }
            } catch {
                await MainActor.run { self.isProcessingAttachments = false }
            }
        }
    }

    func removeAttachment(_ attachment: ChatAttachment) {
        draftAttachments.removeAll { $0.id == attachment.id }
    }

    func sendDraft() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = draftAttachments
        guard !trimmed.isEmpty || !attachments.isEmpty else { return }

        let sessionId = currentSessionId ?? createSessionForDraft()

        if !missingAttachments(for: sessionId).isEmpty {
            queueMissingAttachments(for: sessionId)
            return
        }

        let parentId: UUID? = {
            if let editingId = editingMessageId {
                let existing = messageStore[sessionId]?.first { $0.id == editingId }
                return existing?.parentId
            }
            return buildSelectedPath(for: sessionId).last?.id
        }()

        let meta: [AttachmentMeta] = attachments.map { attachment in
            AttachmentMeta(
                id: attachment.id.uuidString.lowercased(),
                kind: attachment.kind == .image ? .image : .document,
                size: attachment.size,
                name: attachment.name
            )
        }

        guard let inserted = try? chatDb.insertMessage(
            sessionUuid: sessionId.uuidString,
            sender: .selfUser,
            text: trimmed,
            parentMessageUuid: parentId?.uuidString,
            attachments: meta
        ), let messageId = UUID(uuidString: inserted.uuid) else {
            return
        }

        let timestamp = Date(timeIntervalSince1970: Double(inserted.createdAtUs) / 1_000_000.0)

        let userNode = MessageNode(
            id: messageId,
            sessionId: sessionId,
            parentId: parentId,
            role: .user,
            text: trimmed,
            timestamp: timestamp,
            attachments: attachments,
            isInterrupted: false,
            tokensPerSecond: nil
        )

        messageStore[sessionId, default: []].append(userNode)
        updateSelection(for: sessionId, parentId: parentId, childId: userNode.id)

        draftText = ""
        draftAttachments = []
        editingMessageId = nil

        updateSessionPreview(sessionId: sessionId, preview: trimmed, date: timestamp)
        rebuildMessages(for: sessionId)
        startGeneration(for: userNode)
        syncNow(showErrors: false)
    }

    func stopGenerating() {
        stopRequested = true
        provider.stopGeneration()
    }

    func cancelDownload() {
        generationTask?.cancel()
        provider.cancelDownload()
        stopRequested = true
        activeGenerationId = nil
        activeGenerationSessionId = nil
        isGenerating = false
        isDownloading = false
        streamingResponse = ""
        streamingParentId = nil
        downloadToast = nil
    }

    func retryDownload() {
        let target = modelSettings.currentTarget()
        Task {
            do {
                try await provider.ensureModelReady(target: target) { progress in
                    Task { @MainActor in
                        self.handleProgress(progress)
                    }
                }
            } catch {
                if isCancellation(error) {
                    return
                }
                downloadToast = DownloadToastState(phase: .errorDownload, percent: -1, status: error.localizedDescription, offerRetryDownload: true)
            }
        }
    }

    func retryAssistantResponse(_ message: ChatMessage) {
        guard message.role == .assistant else { return }
        guard let sessionId = currentSessionId else { return }
        guard let parent = messageStore[sessionId]?.first(where: { $0.id == message.id })?.parentId,
              let userNode = messageStore[sessionId]?.first(where: { $0.id == parent }) else {
            return
        }
        if !missingAttachments(for: sessionId).isEmpty {
            queueMissingAttachments(for: sessionId)
            return
        }
        provider.resetContext()
        startGeneration(for: userNode)
        syncNow(showErrors: false)
    }

    func changeBranch(for message: ChatMessage, delta: Int) {
        guard let sessionId = currentSessionId else { return }
        guard let node = messageStore[sessionId]?.first(where: { $0.id == message.id }) else { return }
        let parentKey = node.parentId?.uuidString ?? "__root__"
        let parentId = node.parentId ?? rootId
        let siblings = dedupeSiblings(childrenFor(sessionId: sessionId, parentId: parentId))
        guard !siblings.isEmpty else { return }
        let selectionMap = branchSelections[sessionId] ?? [:]
        let currentId = selectionMap[parentKey] ?? siblings.last?.id
        let currentIndex = siblings.firstIndex { $0.id == currentId } ?? (siblings.count - 1)
        let nextIndex = max(0, min(siblings.count - 1, currentIndex + delta))
        branchSelections[sessionId, default: [:]][parentKey] = siblings[nextIndex].id
        rebuildMessages(for: sessionId)
    }

    private func createSessionForDraft() -> UUID {
        let created = (try? chatDb.createSession(title: "New chat"))
        let sessionId = created.flatMap { UUID(uuidString: $0.uuid) } ?? UUID()
        let updatedAt = created.map { Date(timeIntervalSince1970: Double($0.updatedAtUs) / 1_000_000.0) } ?? Date()

        let session = ChatSession(id: sessionId, title: created?.title ?? "New chat", lastMessage: "", updatedAt: updatedAt)
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        messageStore[session.id] = []
        branchSelections[session.id] = [:]
        refreshAttachmentDownloadState()
        return session.id
    }

    private func startGeneration(for userNode: MessageNode) {
        generationTask?.cancel()
        stopRequested = false
        let generationId = UUID()
        activeGenerationId = generationId
        activeGenerationSessionId = userNode.sessionId
        isGenerating = true
        isDownloading = false
        streamingResponse = ""
        streamingParentId = userNode.id
        downloadToast = nil
        rebuildMessages(for: userNode.sessionId)

        let target = modelSettings.currentTarget()

        generationTask = Task {
            do {
                try await provider.ensureModelReady(target: target) { progress in
                    Task { @MainActor in
                        guard self.activeGenerationId == generationId else { return }
                        self.handleProgress(progress)
                    }
                }
            } catch {
                if isCancellation(error) {
                    if self.activeGenerationId == generationId {
                        isGenerating = false
                        isDownloading = false
                        streamingParentId = nil
                        downloadToast = nil
                        activeGenerationId = nil
                        activeGenerationSessionId = nil
                    }
                    syncNow(showErrors: false)
                    return
                }
                if self.activeGenerationId == generationId {
                    isGenerating = false
                    isDownloading = false
                    streamingParentId = nil
                    downloadToast = DownloadToastState(phase: .errorDownload, percent: -1, status: error.localizedDescription, offerRetryDownload: true)
                    activeGenerationId = nil
                    activeGenerationSessionId = nil
                }
                syncNow(showErrors: false)
                return
            }

            let prompt = buildPrompt(text: userNode.text, attachments: userNode.attachments)
            let history = buildHistory(sessionId: userNode.sessionId, promptText: prompt.text, currentMessageId: userNode.id)
            let messages = history + [InferenceMessage(text: prompt.text, isUser: true, hasAttachments: !userNode.attachments.isEmpty)]

            let bufferLock = NSLock()
            var buffer = ""
            var tokenCount = 0

            do {
                let summary = try await provider.generateChat(
                    target: target,
                    messages: messages,
                    imageFiles: prompt.imageFiles,
                    temperature: 0.7,
                    maxTokens: target.maxTokens ?? 1024
                ) { token in
                    bufferLock.lock()
                    buffer.append(token)
                    tokenCount += self.estimateTokens(token)
                    let snapshot = buffer
                    bufferLock.unlock()

                    Task { @MainActor in
                        guard self.activeGenerationId == generationId else { return }
                        self.streamingResponse = snapshot
                    }
                }

                finishGeneration(parent: userNode, response: buffer, tokenCount: tokenCount, totalTimeMs: summary.totalTimeMs, interrupted: false, generationId: generationId)
            } catch {
                let interrupted = stopRequested || error.localizedDescription.lowercased().contains("cancel")
                finishGeneration(parent: userNode, response: buffer, tokenCount: tokenCount, totalTimeMs: nil, interrupted: interrupted, generationId: generationId)
            }
        }
    }

    private func finishGeneration(parent: MessageNode, response: String, tokenCount: Int, totalTimeMs: Int64?, interrupted: Bool, generationId: UUID) {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let tokensPerSecond: Double? = {
                guard let totalTimeMs, totalTimeMs > 0 else { return nil }
                return Double(tokenCount) / (Double(totalTimeMs) / 1000.0)
            }()

            let meta: [AttachmentMeta] = []
            if let inserted = try? chatDb.insertMessage(
                sessionUuid: parent.sessionId.uuidString,
                sender: .other,
                text: trimmed,
                parentMessageUuid: parent.id.uuidString,
                attachments: meta
            ), let assistantId = UUID(uuidString: inserted.uuid) {
                let timestamp = Date(timeIntervalSince1970: Double(inserted.createdAtUs) / 1_000_000.0)
                let assistant = MessageNode(
                    id: assistantId,
                    sessionId: parent.sessionId,
                    parentId: parent.id,
                    role: .assistant,
                    text: trimmed,
                    timestamp: timestamp,
                    attachments: [],
                    isInterrupted: interrupted,
                    tokensPerSecond: tokensPerSecond
                )

                messageStore[parent.sessionId, default: []].append(assistant)
                updateSelection(for: parent.sessionId, parentId: parent.id, childId: assistant.id)
                updateSessionPreview(sessionId: parent.sessionId, preview: trimmed, date: assistant.timestamp)
            }
        }

        if activeGenerationId == generationId {
            isGenerating = false
            isDownloading = false
            streamingResponse = ""
            streamingParentId = nil
            downloadToast = nil
            activeGenerationId = nil
            activeGenerationSessionId = nil
        }

        if currentSessionId == parent.sessionId {
            rebuildMessages(for: parent.sessionId)
        }
        syncNow(showErrors: false)
    }

    private func handleProgress(_ progress: InferenceDownloadProgress) {
        if progress.percent == -1 {
            downloadToast = DownloadToastState(phase: .errorDownload, percent: -1, status: progress.status, offerRetryDownload: true)
            isDownloading = false
            return
        }

        let isLoading = progress.status.localizedCaseInsensitiveContains("Loading")
        let isReady = progress.status.localizedCaseInsensitiveContains("Ready")

        if isLoading {
            downloadToast = DownloadToastState(phase: .loading, percent: progress.percent, status: progress.status, offerRetryDownload: false)
            isDownloading = true
            return
        }

        if isReady {
            downloadToast = DownloadToastState(phase: .complete, percent: 100, status: progress.status, offerRetryDownload: false)
            isDownloading = false
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if self.downloadToast?.phase == .complete {
                    self.downloadToast = nil
                }
            }
            return
        }

        downloadToast = DownloadToastState(phase: .downloading, percent: progress.percent, status: progress.status, offerRetryDownload: false)
        isDownloading = progress.percent >= 0 && progress.percent < 100
    }

    private func buildSyncAuth() -> SyncAuth? {
        guard CredentialStore.shared.hasConfiguredAccount,
              let token = CredentialStore.shared.token,
              let masterKey = CredentialStore.shared.masterKey else {
            return nil
        }

        let baseUrl = EnsuDeveloperSettings.networkConfiguration.apiEndpoint.absoluteString
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return SyncAuth(
            baseUrl: baseUrl,
            authToken: token,
            masterKey: masterKey,
            userAgent: EntePlatform.current.userAgent,
            clientPackage: EnteApp.ensu.packageIdentifier,
            clientVersion: version
        )
    }

    private nonisolated func syncErrorMessage(from error: Error) -> String {
        if let syncError = error as? SyncError {
            switch syncError {
            case let .Message(message):
                return message
            }
        }
        let description = error.localizedDescription
        if description.isEmpty {
            return String(describing: error)
        }
        return description
    }

    private func queueMissingAttachments(for sessionId: UUID) {
        let missing = missingAttachments(for: sessionId)
        guard !missing.isEmpty else {
            refreshAttachmentDownloadState()
            return
        }

        var updated = attachmentDownloads
        for item in missing {
            if let existingIndex = updated.firstIndex(where: { $0.id == item.id }) {
                if updated[existingIndex].status == .failed || updated[existingIndex].status == .canceled {
                    updated[existingIndex].status = .queued
                    updated[existingIndex].errorMessage = nil
                }
            } else {
                updated.append(item)
            }
        }

        attachmentDownloads = updated
        for item in missing {
            if !attachmentDownloadQueue.contains(item.id) && attachmentDownloadTasks[item.id] == nil {
                attachmentDownloadQueue.append(item.id)
            }
        }

        refreshAttachmentDownloadState()
        startNextAttachmentDownloads()
    }

    private func missingAttachments(for sessionId: UUID) -> [AttachmentDownloadItem] {
        guard let nodes = messageStore[sessionId], !nodes.isEmpty else { return [] }
        var seen = Set<String>()
        var missing: [AttachmentDownloadItem] = []

        for node in nodes {
            for attachment in node.attachments {
                let id = attachment.id.uuidString.lowercased()
                if seen.contains(id) { continue }
                seen.insert(id)
                let path = attachmentsDir.appendingPathComponent(id).path
                if FileManager.default.fileExists(atPath: path) {
                    attachmentDownloadTasks[id]?.cancel()
                    attachmentDownloadTasks[id] = nil
                    attachmentDownloadQueue.removeAll { $0 == id }
                    attachmentDownloads.removeAll { $0.id == id }
                    continue
                }
                let existing = attachmentDownloads.first { $0.id == id }
                let status = existing?.status ?? .queued
                missing.append(AttachmentDownloadItem(
                    id: id,
                    sessionId: sessionId,
                    name: attachment.name,
                    size: attachment.size,
                    status: status,
                    errorMessage: existing?.errorMessage
                ))
            }
        }

        return missing
    }

    private func startNextAttachmentDownloads() {
        guard attachmentDownloadTasks.count < maxAttachmentDownloads else { return }
        guard let auth = buildSyncAuth() else { return }

        while attachmentDownloadTasks.count < maxAttachmentDownloads, !attachmentDownloadQueue.isEmpty {
            let id = attachmentDownloadQueue.removeFirst()
            guard let index = attachmentDownloads.firstIndex(where: { $0.id == id }) else { continue }
            if attachmentDownloads[index].status == .canceled || attachmentDownloads[index].status == .completed {
                continue
            }
            let sessionId = attachmentDownloads[index].sessionId
            attachmentDownloads[index].status = .downloading

            let task = Task.detached { [weak self] in
                guard let self else { return }
                do {
                    _ = try self.syncEngine.downloadAttachment(
                        attachmentId: id,
                        sessionUuid: sessionId.uuidString,
                        auth: auth
                    )
                    await MainActor.run {
                        self.updateAttachmentDownloadStatus(id: id, status: .completed, errorMessage: nil)
                    }
                } catch {
                    let message = self.syncErrorMessage(from: error)
                    await MainActor.run {
                        self.updateAttachmentDownloadStatus(id: id, status: .failed, errorMessage: message)
                    }
                }
            }
            attachmentDownloadTasks[id] = task
        }
    }

    private func updateAttachmentDownloadStatus(
        id: String,
        status: AttachmentDownloadItem.Status,
        errorMessage: String?
    ) {
        if let index = attachmentDownloads.firstIndex(where: { $0.id == id }) {
            if attachmentDownloads[index].status != .canceled {
                attachmentDownloads[index].status = status
                attachmentDownloads[index].errorMessage = status == .failed ? errorMessage : nil
            }
        }
        attachmentDownloadTasks[id] = nil
        refreshAttachmentDownloadState()
        startNextAttachmentDownloads()
    }

    private func refreshAttachmentDownloadState() {
        if let sessionId = currentSessionId {
            currentSessionMissingAttachments = missingAttachments(for: sessionId)
        } else {
            currentSessionMissingAttachments = []
        }
    }

    func cancelAttachmentDownload(_ id: String) {
        if let task = attachmentDownloadTasks[id] {
            task.cancel()
            attachmentDownloadTasks[id] = nil
        }
        if let index = attachmentDownloads.firstIndex(where: { $0.id == id }) {
            attachmentDownloads[index].status = .canceled
        }
        attachmentDownloadQueue.removeAll { $0 == id }
        refreshAttachmentDownloadState()
        startNextAttachmentDownloads()
    }

    private func purgeAttachmentDownloads(for sessionId: UUID) {
        let ids = attachmentDownloads.filter { $0.sessionId == sessionId }.map { $0.id }
        for id in ids {
            attachmentDownloadTasks[id]?.cancel()
            attachmentDownloadTasks[id] = nil
            attachmentDownloadQueue.removeAll { $0 == id }
            attachmentDownloads.removeAll { $0.id == id }
        }
        refreshAttachmentDownloadState()
        startNextAttachmentDownloads()
    }

    private func reloadFromDb() {
        let loaded = (try? chatDb.listSessions()) ?? []
        let refreshed: [ChatSession] = loaded.compactMap { session in
            guard let id = UUID(uuidString: session.uuid) else { return nil }
            let lastMessage = (try? chatDb.getMessages(sessionUuid: session.uuid))?.last?.text ?? ""
            return ChatSession(
                id: id,
                title: session.title,
                lastMessage: lastMessage,
                updatedAt: Date(timeIntervalSince1970: Double(session.updatedAtUs) / 1_000_000.0)
            )
        }

        let selected = currentSessionId
        let resolved = selected.flatMap { id in
            refreshed.first(where: { $0.id == id })?.id
        } ?? (selected == nil ? nil : refreshed.first?.id)

        sessions = refreshed
        currentSessionId = resolved
        messages = []
        messageStore = [:]
        branchSelections = [:]

        for session in refreshed {
            messageStore[session.id] = []
            branchSelections[session.id] = [:]
        }

        if let current = resolved {
            loadMessagesFromDb(for: current)
            rebuildMessages(for: current)
            queueMissingAttachments(for: current)
        } else {
            refreshAttachmentDownloadState()
        }
    }

    private func loadMessagesFromDb(for sessionId: UUID) {
        guard messageStore[sessionId] != nil else {
            messageStore[sessionId] = []
            branchSelections[sessionId] = [:]
            return
        }

        guard let rawMessages = try? chatDb.getMessages(sessionUuid: sessionId.uuidString) else {
            messageStore[sessionId] = []
            branchSelections[sessionId] = [:]
            return
        }

        let nodes: [MessageNode] = rawMessages.compactMap { msg in
            guard let messageId = UUID(uuidString: msg.uuid) else { return nil }
            let parentId = msg.parentMessageUuid.flatMap { UUID(uuidString: $0) }
            let role: ChatMessage.Role = (msg.sender == .selfUser) ? .user : .assistant
            let timestamp = Date(timeIntervalSince1970: Double(msg.createdAtUs) / 1_000_000.0)

            let attachments: [ChatAttachment] = msg.attachments.compactMap { meta in
                guard let attachmentId = UUID(uuidString: meta.id) else { return nil }
                let kind: ChatAttachment.Kind = (meta.kind == .image) ? .image : .document
                let url = attachmentsDir.appendingPathComponent(meta.id)
                return ChatAttachment(
                    id: attachmentId,
                    name: meta.name,
                    size: meta.size,
                    kind: kind,
                    url: url,
                    isUploading: false
                )
            }

            return MessageNode(
                id: messageId,
                sessionId: sessionId,
                parentId: parentId,
                role: role,
                text: msg.text,
                timestamp: timestamp,
                attachments: attachments,
                isInterrupted: false,
                tokensPerSecond: nil
            )
        }

        messageStore[sessionId] = nodes
        // Branch selection is computed in-memory.
        branchSelections[sessionId] = [:]
    }

    private func rebuildMessages(for sessionId: UUID) {
        let path = buildSelectedPath(for: sessionId)
        let childrenMap = childrenByParent(sessionId: sessionId)
        let selectionMap = branchSelections[sessionId, default: [:]]

        messages = path.map { node in
            let parentKey = node.parentId?.uuidString ?? "__root__"
            let parentId = node.parentId ?? rootId
            let siblings = dedupeSiblings(childrenMap[parentId] ?? [])
            let selectedId = selectionMap[parentKey]
            let index = siblings.firstIndex { $0.id == selectedId } ?? (siblings.count - 1)

            return ChatMessage(
                id: node.id,
                role: node.role,
                text: node.text,
                timestamp: node.timestamp,
                attachments: node.attachments,
                isInterrupted: node.isInterrupted,
                tokensPerSecond: node.tokensPerSecond,
                branchIndex: max(1, index + 1),
                branchCount: max(1, siblings.count)
            )
        }
    }

    private func buildSelectedPath(for sessionId: UUID) -> [MessageNode] {
        guard let nodes = messageStore[sessionId], !nodes.isEmpty else { return [] }
        let byId = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let childrenMap = childrenByParent(sessionId: sessionId)
        let roots = dedupeSiblings(nodes.filter { node in
            guard let parentId = node.parentId else { return true }
            return byId[parentId] == nil
        })
        guard !roots.isEmpty else { return [] }

        let selectionMap = branchSelections[sessionId, default: [:]]
        var current = selectChild(selectionMap: selectionMap, selectionKey: "__root__", candidates: roots)
        var path: [MessageNode] = []
        var visited = Set<UUID>()

        while let node = current, visited.insert(node.id).inserted {
            path.append(node)
            if node.id == streamingParentId { break }
            let children = dedupeSiblings(childrenMap[node.id] ?? [])
            if children.isEmpty { break }
            current = selectChild(selectionMap: selectionMap, selectionKey: node.id.uuidString, candidates: children)
        }
        return path
    }

    private func selectChild(selectionMap: [String: UUID], selectionKey: String, candidates: [MessageNode]) -> MessageNode? {
        guard !candidates.isEmpty else { return nil }
        if let selectedId = selectionMap[selectionKey],
           let selected = candidates.first(where: { $0.id == selectedId }) {
            return selected
        }
        return candidates.last
    }

    private func childrenByParent(sessionId: UUID) -> [UUID: [MessageNode]] {
        var map: [UUID: [MessageNode]] = [:]
        guard let nodes = messageStore[sessionId] else { return map }
        let byId = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        for node in nodes {
            let parent = node.parentId.flatMap { byId[$0] != nil ? $0 : nil } ?? rootId
            map[parent, default: []].append(node)
        }
        return map
    }

    private func childrenFor(sessionId: UUID, parentId: UUID) -> [MessageNode] {
        let map = childrenByParent(sessionId: sessionId)
        return map[parentId] ?? []
    }

    private func dedupeSiblings(_ nodes: [MessageNode]) -> [MessageNode] {
        guard nodes.count > 1 else { return nodes.sorted(by: { $0.timestamp < $1.timestamp }) }
        let sorted = nodes.sorted(by: { $0.timestamp < $1.timestamp })
        var result: [MessageNode] = []
        for node in sorted {
            if let last = result.last, isDuplicate(last, node) {
                continue
            }
            result.append(node)
        }
        return result
    }

    private func isDuplicate(_ lhs: MessageNode, _ rhs: MessageNode) -> Bool {
        guard lhs.role == rhs.role else { return false }
        guard lhs.text == rhs.text else { return false }
        guard attachmentSignature(lhs.attachments) == attachmentSignature(rhs.attachments) else { return false }
        return abs(lhs.timestamp.timeIntervalSince(rhs.timestamp)) <= 2
    }

    private func attachmentSignature(_ attachments: [ChatAttachment]) -> [String] {
        attachments.map { "\($0.kind)-\($0.name)" }
    }

    private func updateSelection(for sessionId: UUID, parentId: UUID?, childId: UUID) {
        let key = parentId?.uuidString ?? "__root__"
        branchSelections[sessionId, default: [:]][key] = childId
    }

    private func updateSessionPreview(sessionId: UUID, preview: String, date: Date) {
        sessions = sessions.map { session in
            guard session.id == sessionId else { return session }
            var updated = session
            updated.lastMessage = preview
            updated.updatedAt = date
            return updated
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return error.localizedDescription.localizedCaseInsensitiveContains("cancel")
    }

    private nonisolated func attachmentsDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("llmchat", isDirectory: true)
            .appendingPathComponent("chat_attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    private nonisolated func writeAttachment(data: Data, attachmentId: UUID) throws -> URL {
        let dir = try attachmentsDirectory()
        let destination = dir.appendingPathComponent(attachmentId.uuidString.lowercased())
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private nonisolated func copyAttachment(from url: URL, attachmentId: UUID) throws -> URL {
        let dir = try attachmentsDirectory()
        let destination = dir.appendingPathComponent(attachmentId.uuidString.lowercased())

        let needsSecurity = url.startAccessingSecurityScopedResource()
        defer {
            if needsSecurity {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    private func buildPrompt(text: String, attachments: [ChatAttachment]) -> PromptResult {
        var prompt = text
        let documents = attachments.filter { $0.kind == .document }
        let images = attachments.filter { $0.kind == .image }

        for (index, attachment) in documents.enumerated() {
            prompt += "\n\n----- BEGIN DOCUMENT: Document \(index + 1) -----\n"
            prompt += "Attached document: \(attachment.name)\n"
            prompt += "----- END DOCUMENT: Document \(index + 1) -----"
        }

        let imageFiles = images.compactMap { $0.url }
        if !imageFiles.isEmpty {
            let mediaMarker = "<__media__>"
            prompt += "\n\n[\(imageFiles.count) image attachment"
            if imageFiles.count > 1 { prompt += "s" }
            prompt += " provided]"
            for _ in imageFiles {
                prompt += "\n\(mediaMarker)"
            }
        }

        return PromptResult(text: prompt, imageFiles: imageFiles)
    }

    private func buildHistory(sessionId: UUID, promptText: String, currentMessageId: UUID) -> [InferenceMessage] {
        let path = buildSelectedPath(for: sessionId)
        let history = path.prefix { $0.id != currentMessageId }
        if history.isEmpty { return [] }

        let target = modelSettings.currentTarget()
        let contextSize = target.contextLength ?? 4096
        let maxTokens = target.maxTokens ?? 1024
        var budget = contextSize - maxTokens - 256
        budget -= estimateTokens(promptText)
        if budget <= 0 { return [] }

        var selected: [InferenceMessage] = []
        for node in history.reversed() {
            let text = historyText(node)
            let cost = estimateTokens(text)
            if cost <= budget {
                selected.append(InferenceMessage(text: text, isUser: node.role == .user, hasAttachments: !node.attachments.isEmpty))
                budget -= cost
            } else if selected.isEmpty {
                selected.append(InferenceMessage(text: trimToBudget(text, budget: budget), isUser: node.role == .user, hasAttachments: !node.attachments.isEmpty))
                break
            } else {
                break
            }
        }
        return selected.reversed()
    }

    private func historyText(_ node: MessageNode) -> String {
        var text = node.text
        if node.role == .assistant {
            text = text.replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: "<todo_list>[\\s\\S]*?</todo_list>", with: "", options: .regularExpression)
        } else if !node.attachments.isEmpty {
            text += "\n\n[\(node.attachments.count) attachments attached]"
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func trimToBudget(_ text: String, budget: Int) -> String {
        guard budget > 0 else { return "" }
        let maxChars = budget * 4
        if text.count <= maxChars { return text }
        return String(text.suffix(maxChars))
    }

    private func estimateTokens(_ text: String) -> Int {
        max(1, text.count / 4)
    }

    private struct MessageNode: Identifiable {
        let id: UUID
        let sessionId: UUID
        let parentId: UUID?
        let role: ChatMessage.Role
        let text: String
        let timestamp: Date
        let attachments: [ChatAttachment]
        let isInterrupted: Bool
        let tokensPerSecond: Double?
    }

    private struct PromptResult {
        let text: String
        let imageFiles: [URL]
    }
}
