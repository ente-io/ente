import Foundation

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

    private let provider: InferenceRsProvider
    private let modelSettings = ModelSettingsStore.shared

    private var messageStore: [UUID: [MessageNode]] = [:]
    private var branchSelections: [UUID: [String: UUID]] = [:]
    private let rootId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    private var generationTask: Task<Void, Never>?
    private var stopRequested = false
    private var activeGenerationId: UUID?
    private var activeGenerationSessionId: UUID?

    init() {
        let session = ChatSession(title: "New chat", lastMessage: "", updatedAt: Date())
        self.sessions = [session]
        self.currentSessionId = session.id
        self.messages = []
        self.messageStore[session.id] = []
        self.branchSelections[session.id] = [:]

        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        self.provider = InferenceRsProvider(modelDir: baseDir.appendingPathComponent("llm", isDirectory: true))
    }

    var currentSession: ChatSession? {
        guard let currentSessionId else { return nil }
        return sessions.first { $0.id == currentSessionId }
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

        let session = ChatSession(title: "New chat", lastMessage: "", updatedAt: Date())
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        messageStore[session.id] = []
        branchSelections[session.id] = [:]
        rebuildMessages(for: session.id)
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
        rebuildMessages(for: session.id)
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
        sessions.removeAll { $0.id == session.id }
        messageStore[session.id] = nil
        branchSelections[session.id] = nil
        if currentSessionId == session.id {
            currentSessionId = sessions.first?.id
            if let next = currentSessionId {
                rebuildMessages(for: next)
            } else {
                messages = []
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
        guard !isGenerating && !isDownloading else { return }
        isProcessingAttachments = true

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let url = try self.writeAttachment(data: data, fileName: fileName ?? "photo.jpg")
                let attachment = ChatAttachment(
                    name: url.lastPathComponent,
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
        guard !isGenerating && !isDownloading else { return }
        isProcessingAttachments = true

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let storedUrl = try self.copyAttachment(from: url)
                let size = (try? FileManager.default.attributesOfItem(atPath: storedUrl.path)[.size] as? NSNumber)?.int64Value ?? 0
                let attachment = ChatAttachment(
                    name: storedUrl.lastPathComponent,
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
        let timestamp = Date()

        let parentId: UUID? = {
            if let editingId = editingMessageId {
                let existing = messageStore[sessionId]?.first { $0.id == editingId }
                return existing?.parentId
            }
            return buildSelectedPath(for: sessionId).last?.id
        }()

        let userNode = MessageNode(
            id: UUID(),
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
        provider.resetContext()
        startGeneration(for: userNode)
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
        let session = ChatSession(title: "New chat", lastMessage: "", updatedAt: Date())
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        messageStore[session.id] = []
        branchSelections[session.id] = [:]
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

            let assistant = MessageNode(
                id: UUID(),
                sessionId: parent.sessionId,
                parentId: parent.id,
                role: .assistant,
                text: trimmed,
                timestamp: Date(),
                attachments: [],
                isInterrupted: interrupted,
                tokensPerSecond: tokensPerSecond
            )

            messageStore[parent.sessionId, default: []].append(assistant)
            updateSelection(for: parent.sessionId, parentId: parent.id, childId: assistant.id)
            updateSessionPreview(sessionId: parent.sessionId, preview: trimmed, date: assistant.timestamp)
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
        let dir = base.appendingPathComponent("llm", isDirectory: true)
            .appendingPathComponent("attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    private nonisolated func writeAttachment(data: Data, fileName: String) throws -> URL {
        let dir = try attachmentsDirectory()
        let safeName = fileName.replacingOccurrences(of: "/", with: "_")
        let destination = dir.appendingPathComponent("\(UUID().uuidString)_\(safeName)")
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private nonisolated func copyAttachment(from url: URL) throws -> URL {
        let dir = try attachmentsDirectory()
        let safeName = url.lastPathComponent.replacingOccurrences(of: "/", with: "_")
        let destination = dir.appendingPathComponent("\(UUID().uuidString)_\(safeName)")

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
