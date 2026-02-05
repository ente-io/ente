import Foundation
import SwiftUI
#if canImport(EnteCore)
import EnteCore
#else
struct SyncAuth {
    let baseUrl: String
    let authToken: String
    let masterKey: Data
    let userAgent: String
    let clientPackage: String
    let clientVersion: String?
}

enum SyncError: Error {
    case Message(String)
    case SyncInProgress
}

struct MigrationConfig {
    let batchSize: Int64
    let priority: MigrationPriority
}

enum MigrationPriority {
    case recentFirst
    case oldestFirst
}

enum MigrationState {
    case notNeeded
    case inProgress
    case complete
    case failed
}

struct MigrationProgress {
    let state: MigrationState
    let processed: Int64
    let remaining: Int64
    let total: Int64
}

protocol MigrationProgressCallback {
    func onProgress(progress: MigrationProgress)
}

final class CredentialStore {
    static let shared = CredentialStore()
    var hasConfiguredAccount: Bool { false }
    var token: String? { nil }
    var masterKey: Data? { nil }

    func getOrCreateChatDbKey() -> Data {
        Data()
    }
}

struct EntePlatform {
    static let current = EntePlatform()
    var userAgent: String { "ensu" }
}

enum EnteApp {
    case ensu

    var packageIdentifier: String {
        "ensu"
    }
}

enum EnsuLogLevel: String {
    case info
    case warning
    case error
}

struct EnsuLogger {
    let tag: String

    func info(_ message: String, details: String? = nil) {}
    func warning(_ message: String, details: String? = nil) {}
    func error(_ message: String, _ error: Error? = nil, details: String? = nil) {}
}

final class EnsuLogging {
    static let shared = EnsuLogging()

    func start() {}

    func logger(_ tag: String) -> EnsuLogger {
        EnsuLogger(tag: tag)
    }

    func log(level: EnsuLogLevel, tag: String, message: String, details: String? = nil, error: Error? = nil) {}

    func todayLogFileURL() -> URL { URL(fileURLWithPath: "") }
    func listLogFiles() -> [URL] { [] }
    func readLogText(fileURL: URL) -> String { "" }
    func createLogsArchive() throws -> URL { URL(fileURLWithPath: "") }
}

struct NetworkConfiguration {
    let apiEndpoint: URL

    static var `default`: NetworkConfiguration {
        NetworkConfiguration(apiEndpoint: URL(string: "https://api.ente.io")!)
    }
}

enum EnsuDeveloperSettings {
    static var networkConfiguration: NetworkConfiguration {
        .default
    }
}

struct InferenceModelTarget: Equatable {
    let id: String
    let url: String
    let mmprojUrl: String?
    let contextLength: Int?
    let maxTokens: Int?
}

struct InferenceDownloadProgress: Equatable {
    let percent: Int
    let status: String
}

enum InferenceMessageRole {
    case user
    case assistant
    case system

    var roleString: String {
        switch self {
        case .user:
            return "user"
        case .assistant:
            return "assistant"
        case .system:
            return "system"
        }
    }
}

struct InferenceMessage {
    let text: String
    let role: InferenceMessageRole
    let hasAttachments: Bool
}

struct InferenceGenerationSummary {
    let jobId: Int64
    let generatedTokens: Int
    let totalTimeMs: Int64?
}

final class InferenceRsProvider {
    init(modelDir: URL) {
        _ = modelDir
    }

    func ensureModelReady(
        target: InferenceModelTarget,
        onProgress: @escaping (InferenceDownloadProgress) -> Void
    ) async throws {
        _ = (target, onProgress)
    }

    func generateChat(
        target: InferenceModelTarget,
        messages: [InferenceMessage],
        imageFiles: [URL],
        temperature: Float,
        maxTokens: Int,
        onToken: @escaping (String) -> Void
    ) async throws -> InferenceGenerationSummary {
        _ = (target, messages, imageFiles, temperature, maxTokens, onToken)
        return InferenceGenerationSummary(jobId: 0, generatedTokens: 0, totalTimeMs: nil)
    }

    func isModelDownloaded(target: InferenceModelTarget) -> Bool {
        _ = target
        return true
    }

    func estimatedDownloadSize(target: InferenceModelTarget) async -> Int64? {
        _ = target
        return nil
    }

    func stopGeneration() {}

    func resetContext() {}

    func cancelDownload() {}
}

@MainActor
final class ModelSettingsStore: ObservableObject {
    static let shared = ModelSettingsStore()

    var temperature: String = ""
    var contextLength: String = ""
    var maxTokens: String = ""
    var useCustomModel: Bool = false
    var modelUrl: String = ""
    var mmprojUrl: String = ""

    func currentTarget() -> InferenceModelTarget {
        let context = Int(contextLength)
        let maxOutput = Int(maxTokens)
        return InferenceModelTarget(
            id: "default",
            url: "",
            mmprojUrl: nil,
            contextLength: context,
            maxTokens: maxOutput
        )
    }
}

enum MessageSender {
    case selfUser
    case other
}

enum AttachmentKind {
    case image
    case document
}

struct AttachmentMeta {
    let id: String
    let kind: AttachmentKind
    let size: Int64
    let name: String
}

struct LlmChatSession {
    let uuid: String
    let title: String
    let updatedAtUs: Int64
}

struct LlmChatMessage {
    let uuid: String
    let sender: MessageSender
    let createdAtUs: Int64
    let text: String
    let parentMessageUuid: String?
    let attachments: [AttachmentMeta]
}

final class LlmChatDb {
    static func open(mainDbPath: String, attachmentsDbPath: String, key: Data) throws -> LlmChatDb {
        _ = (mainDbPath, attachmentsDbPath, key)
        return LlmChatDb()
    }

    func listSessions() throws -> [LlmChatSession] { [] }

    func getMessages(sessionUuid: String) throws -> [LlmChatMessage] {
        _ = sessionUuid
        return []
    }

    func deleteSession(uuid: String) throws {
        _ = uuid
    }

    func insertMessage(
        sessionUuid: String,
        sender: MessageSender,
        text: String,
        parentMessageUuid: String?,
        attachments: [AttachmentMeta]
    ) throws -> LlmChatMessage {
        _ = (sessionUuid, sender, text, parentMessageUuid, attachments)
        return LlmChatMessage(
            uuid: UUID().uuidString,
            sender: sender,
            createdAtUs: Int64(Date().timeIntervalSince1970 * 1_000_000),
            text: text,
            parentMessageUuid: parentMessageUuid,
            attachments: attachments
        )
    }

    func createSession(title: String) throws -> LlmChatSession {
        LlmChatSession(uuid: UUID().uuidString, title: title, updatedAtUs: Int64(Date().timeIntervalSince1970 * 1_000_000))
    }

    func updateSessionTitle(uuid: String, title: String) throws {
        _ = (uuid, title)
    }
}

final class LlmChatSync {
    static func open(
        mainDbPath: String,
        attachmentsDbPath: String,
        dbKey: Data,
        attachmentsDir: String,
        metaDir: String,
        plaintextDir: String
    ) throws -> LlmChatSync {
        _ = (mainDbPath, attachmentsDbPath, dbKey, attachmentsDir, metaDir, plaintextDir)
        return LlmChatSync()
    }

    func sync(auth: SyncAuth) throws -> Bool {
        _ = auth
        return true
    }

    func checkMigrationStatusLocal() -> MigrationState? {
        nil
    }

    func checkMigrationStatus(auth: SyncAuth) throws -> MigrationState {
        _ = auth
        return .inProgress
    }

    func syncWithProgress(
        auth: SyncAuth,
        config: MigrationConfig,
        callback: MigrationProgressCallback
    ) throws -> Bool {
        _ = (auth, config, callback)
        return true
    }

    func resetSyncState() throws {
    }

    func seedFromOffline(offlineDbPath: String, offlineDbKey: Data) throws {
        _ = (offlineDbPath, offlineDbKey)
    }

    func downloadAttachment(attachmentId: String, sessionUuid: String, auth: SyncAuth) throws -> Bool {
        _ = (attachmentId, sessionUuid, auth)
        return true
    }
}

func fetchChatKey(auth: SyncAuth, syncDbPath: String) throws -> Data {
    _ = (auth, syncDbPath)
    return Data()
}
#endif

#if canImport(EnteCore)

typealias LlmChatSession = Session

enum SyncState: Equatable {
    case idle
    case syncing
    case migrating(processed: Int64, total: Int64)
    case error(String)
}

final class MigrationProgressHandler: MigrationProgressCallback {
    private let handler: @Sendable (MigrationProgress) -> Void

    init(_ handler: @escaping @Sendable (MigrationProgress) -> Void) {
        self.handler = handler
    }

    func onProgress(progress: MigrationProgress) {
        handler(progress)
    }
}

private struct OnlineStorePreparation {
    let chatKey: Data
    let chatDb: LlmChatDb
    let syncEngine: LlmChatSync
}

@MainActor
final class ChatViewModel: ObservableObject {
    private static let defaultTemperature: Float = 0.5
    private static let systemPrompt = "You are a helpful assistant. Use Markdown **bold** to emphasize important terms and key points. For math equations, put $$ on its own line (never inline). Example:\n$$\nx^2 + y^2 = z^2\n$$"
    private static let overflowSafetyTokens = 128
    private static let imageTokenEstimate = 768
    private static let sessionTitleMaxLength = 40
    private static let sessionSummaryMaxWords = 7
    private static let sessionSummaryStoreKey = "ensu.session_summaries"
    private static let sessionSummarySystemPrompt = "You create concise chat titles. Given the provided message, summarize the user's goal in 5-7 words. Use plain words. Don't use markdown characters in the title. No quotes, no emojis, no trailing punctuation, and output only the title."

    private let logger = EnsuLogging.shared.logger("ChatViewModel")

    @Published var sessions: [ChatSession]
    @Published var currentSessionId: UUID?
    @Published var messages: [ChatMessage]
    @Published var streamingResponse: String = ""
    @Published var streamingParentId: UUID? = nil
    @Published var overflowAlert: OverflowAlertState? = nil

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
    @Published var isModelDownloaded: Bool = false
    @Published var modelDownloadSizeBytes: Int64?
    @Published var hasRequestedModelDownload: Bool = false
    @Published var attachmentDownloads: [AttachmentDownloadItem] = []
    @Published var currentSessionMissingAttachments: [AttachmentDownloadItem] = []
    @Published var syncState: SyncState = .idle
    @Published var syncErrorMessage: String?
    @Published var syncSuccessMessage: String?
    @Published var generationErrorMessage: String?

    private let provider: InferenceRsProvider
    private var chatDb: LlmChatDb
    private var syncEngine: LlmChatSync
    private let attachmentsDir: URL
    private let offlineDbPath: String
    private let onlineDbPath: String
    private let syncDbPath: String
    private let syncMetaDir: URL
    private let encryptedAttachmentsDir: URL
    private let offlineDbKey: Data
    private var onlineDbKey: Data?
    private var isOnlineMode = false
    private let modelSettings = ModelSettingsStore.shared

    private var activeDbPath: String {
        isOnlineMode ? onlineDbPath : offlineDbPath
    }

    private var activeDbKey: Data? {
        isOnlineMode ? onlineDbKey : offlineDbKey
    }

    private var messageStore: [UUID: [MessageNode]] = [:]
    private var branchSelections: [UUID: [String: UUID]] = [:]
    private var childrenByParentCache: [UUID: [UUID: [MessageNode]]] = [:]
    private var sessionSummaries: [String: String] = [:]
    private var sessionSummaryTask: Task<Void, Never>?
    private var reloadTask: Task<Void, Never>?
    private let rootId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    private var generationTask: Task<Void, Never>?
    private var modelDownloadTask: Task<Void, Never>?
    private var stopRequested = false
    private var activeGenerationId: UUID?
    private var activeGenerationSessionId: UUID?
    private var pendingSyncRequested = false
    private var pendingSyncShowErrors = false
    private var pendingSyncShowSuccess = false
    private var modelDownloadLoggedStart = false
    private var pendingOverflow: PendingOverflow?
    private var overflowBypassMessageId: UUID?

    private var attachmentDownloadQueue: [String] = []
    private var attachmentDownloadTasks: [String: Task<Void, Never>] = [:]
    private let maxAttachmentDownloads = 2

    init() {
        logger.info("Initializing")
        let summaries = Self.loadSessionSummaries().reduce(into: [String: String]()) { result, item in
            result[item.key.lowercased()] = item.value
        }
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

        let offlineKey = CredentialStore.shared.getOrCreateChatDbKey()
        let offlineDbPath = dbDir.appendingPathComponent("llmchat.db").path
        let onlineDbPath = dbDir.appendingPathComponent("llmchat_online.db").path
        let syncDbPath = dbDir.appendingPathComponent("llmchat_sync.db").path

        let chatDb: LlmChatDb
        do {
            chatDb = try LlmChatDb.open(mainDbPath: offlineDbPath, attachmentsDbPath: syncDbPath, key: offlineKey)
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
                mainDbPath: offlineDbPath,
                attachmentsDbPath: syncDbPath,
                dbKey: offlineKey,
                attachmentsDir: encryptedAttachmentsDir.path,
                metaDir: syncMetaDir.path,
                plaintextDir: attachmentsDir.path
            )
        } catch {
            fatalError("Failed to open chat sync: \(error)")
        }

        // Load sessions/messages.
        let loaded = (try? chatDb.listSessions()) ?? []
        let sessions = Self.buildSessions(from: loaded, chatDb: chatDb, summaries: summaries)

        // Stored properties.
        self.provider = provider
        self.chatDb = chatDb
        self.syncEngine = syncEngine
        self.attachmentsDir = attachmentsDir
        self.offlineDbPath = offlineDbPath
        self.onlineDbPath = onlineDbPath
        self.syncDbPath = syncDbPath
        self.syncMetaDir = syncMetaDir
        self.encryptedAttachmentsDir = encryptedAttachmentsDir
        self.offlineDbKey = offlineKey
        self.sessionSummaries = summaries

        self.sessions = sessions
        self.currentSessionId = nil
        self.messages = []

        for session in sessions {
            self.messageStore[session.id] = []
            self.branchSelections[session.id] = [:]
        }

        if let current = self.currentSessionId {
            loadMessagesFromDb(for: current)
        } else {
            refreshAttachmentDownloadState()
        }

        refreshModelDownloadInfo()
    }

    private func reopenSyncStoresIfNeeded(force: Bool = false) {
        let hasSyncDb = FileManager.default.fileExists(atPath: syncDbPath)
        let hasActiveDb = FileManager.default.fileExists(atPath: activeDbPath)
        if !force && hasSyncDb && hasActiveDb {
            return
        }

        guard let key = activeDbKey else {
            logger.error("Missing active DB key")
            return
        }

        do {
            try? FileManager.default.createDirectory(
                at: syncMetaDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.createDirectory(
                at: encryptedAttachmentsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.createDirectory(
                at: attachmentsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )

            chatDb = try LlmChatDb.open(
                mainDbPath: activeDbPath,
                attachmentsDbPath: syncDbPath,
                key: key
            )
            syncEngine = try LlmChatSync.open(
                mainDbPath: activeDbPath,
                attachmentsDbPath: syncDbPath,
                dbKey: key,
                attachmentsDir: encryptedAttachmentsDir.path,
                metaDir: syncMetaDir.path,
                plaintextDir: attachmentsDir.path
            )
        } catch {
            logger.error("Failed to reopen sync stores: \(error)")
        }
    }

    private func prepareOnlineStores(auth: SyncAuth) async throws {
        let syncDbPath = syncDbPath
        let onlineDbPath = onlineDbPath
        let offlineDbPath = offlineDbPath
        let offlineDbKey = offlineDbKey
        let syncMetaDir = syncMetaDir
        let encryptedAttachmentsDir = encryptedAttachmentsDir
        let attachmentsDir = attachmentsDir
        let existingSyncEngine = syncEngine

        let preparation = try await Task.detached {
            if FileManager.default.fileExists(atPath: syncDbPath) {
                try? existingSyncEngine.resetSyncState()
            }
            try? FileManager.default.removeItem(atPath: onlineDbPath)
            ChatDataCleaner.deleteSyncState()
            try? FileManager.default.createDirectory(
                at: syncMetaDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.createDirectory(
                at: encryptedAttachmentsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.createDirectory(
                at: attachmentsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let chatKey = try fetchChatKey(auth: auth, syncDbPath: syncDbPath)

            let chatDb = try LlmChatDb.open(
                mainDbPath: onlineDbPath,
                attachmentsDbPath: syncDbPath,
                key: chatKey
            )
            let newSyncEngine = try LlmChatSync.open(
                mainDbPath: onlineDbPath,
                attachmentsDbPath: syncDbPath,
                dbKey: chatKey,
                attachmentsDir: encryptedAttachmentsDir.path,
                metaDir: syncMetaDir.path,
                plaintextDir: attachmentsDir.path
            )
            try newSyncEngine.seedFromOffline(offlineDbPath: offlineDbPath, offlineDbKey: offlineDbKey)
            return OnlineStorePreparation(chatKey: chatKey, chatDb: chatDb, syncEngine: newSyncEngine)
        }.value

        onlineDbKey = preparation.chatKey
        isOnlineMode = true
        chatDb = preparation.chatDb
        syncEngine = preparation.syncEngine
    }

    func handleLogout() {
        if FileManager.default.fileExists(atPath: syncDbPath) {
            do {
                try syncEngine.resetSyncState()
            } catch {
                logger.warning("Failed to reset sync state: \(error)")
            }
        }
        ChatDataCleaner.deleteSyncState()
        try? FileManager.default.removeItem(atPath: onlineDbPath)
        onlineDbKey = nil
        isOnlineMode = false
        reopenSyncStoresIfNeeded(force: true)
        reloadFromDb()
    }

    var currentSession: ChatSession? {
        guard let currentSessionId else { return nil }
        return sessions.first { $0.id == currentSessionId }
    }

    var isAttachmentDownloadBlocked: Bool {
        !currentSessionMissingAttachments.isEmpty
    }

    var attachmentDownloadProgress: Double? {
        let active = attachmentDownloads.filter { $0.status != AttachmentDownloadItem.Status.canceled }
        let total = active.count
        guard total > 0 else { return nil }

        let hasPending = active.contains { item in
            item.status == AttachmentDownloadItem.Status.queued ||
                item.status == AttachmentDownloadItem.Status.downloading ||
                item.status == AttachmentDownloadItem.Status.failed
        }
        guard hasPending else { return nil }

        let completed = active.filter { $0.status == AttachmentDownloadItem.Status.completed }.count
        return Double(completed) / Double(total)
    }

    var attachmentDownloadSummary: (completed: Int, total: Int)? {
        let active = attachmentDownloads.filter { $0.status != AttachmentDownloadItem.Status.canceled }
        let total = active.count
        guard total > 0 else { return nil }

        let hasPending = active.contains { item in
            item.status == AttachmentDownloadItem.Status.queued ||
                item.status == AttachmentDownloadItem.Status.downloading ||
                item.status == AttachmentDownloadItem.Status.failed
        }
        guard hasPending else { return nil }

        let completed = active.filter { $0.status == AttachmentDownloadItem.Status.completed }.count
        return (completed, total)
    }

    var modelDownloadSizeText: String {
        guard let bytes = modelDownloadSizeBytes else { return "Approx. size varies by model" }
        return "Approx. \(bytes.formattedFileSize)"
    }

    private func resetGenerationState(stopRequested: Bool = false) {
        generationTask?.cancel()
        provider.stopGeneration()
        self.stopRequested = stopRequested
        activeGenerationId = nil
        activeGenerationSessionId = nil
        isGenerating = false
        isDownloading = false
        streamingResponse = ""
        streamingParentId = nil
        downloadToast = nil
    }

    func sessionTitle(for sessionId: UUID) -> String {
        guard let title = sessions.first(where: { $0.id == sessionId })?.title else { return "Chat" }
        return Self.sessionTitle(from: title, fallback: "Chat")
    }

    func startNewSession() {
        resetGenerationState()
        draftText = ""
        draftAttachments = []
        editingMessageId = nil

        currentSessionId = nil
        messages = []
        refreshAttachmentDownloadState()
    }

    func selectSession(_ session: ChatSession) {
        resetGenerationState()
        currentSessionId = session.id
        messages = []
        loadMessagesFromDb(for: session.id)
    }

    func deleteSession(_ session: ChatSession) {
        if currentSessionId == session.id {
            resetGenerationState()
        }

        if let nodes = messageStore[session.id] {
            for node in nodes {
                logger.info("Message deleted", details: "id=\(node.id.uuidString) session=\(session.id.uuidString) role=\(node.role.rawValue)")
            }
        }
        logger.info("Session deleted", details: "id=\(session.id.uuidString)")
        try? chatDb.deleteSession(uuid: session.id.uuidString)
        sessionSummaries.removeValue(forKey: sessionSummaryKey(session.id))
        persistSessionSummaries()

        sessions.removeAll { $0.id == session.id }
        messageStore[session.id] = nil
        branchSelections[session.id] = nil
        childrenByParentCache[session.id] = nil
        purgeAttachmentDownloads(for: session.id)
        if currentSessionId == session.id {
            currentSessionId = sessions.first?.id
            if let next = currentSessionId {
                messages = []
                loadMessagesFromDb(for: next)
            } else {
                messages = []
                refreshAttachmentDownloadState()
            }
        }
        syncNow()
    }

    func syncNow(showErrors: Bool = true, showSuccess: Bool = false) {
        if isGenerating {
            pendingSyncRequested = true
            pendingSyncShowErrors = pendingSyncShowErrors || showErrors
            pendingSyncShowSuccess = pendingSyncShowSuccess || showSuccess
            return
        }

        let shouldSync = pendingSyncRequested || showErrors || showSuccess
        let shouldShowErrors = pendingSyncShowErrors || showErrors
        let shouldShowSuccess = pendingSyncShowSuccess || showSuccess
        pendingSyncRequested = false
        pendingSyncShowErrors = false
        pendingSyncShowSuccess = false
        guard shouldSync else { return }
        performSync(showErrors: shouldShowErrors, showSuccess: shouldShowSuccess)
    }

    func syncAfterLogin() {
        guard let auth = buildSyncAuth() else {
            syncState = .error("Sign in to sync")
            return
        }

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                try await self.prepareOnlineStores(auth: auth)
            } catch {
                await MainActor.run {
                    self.syncState = .error("Failed to prepare online chats")
                }
                return
            }

            await MainActor.run {
                self.reloadFromDb()
            }

            let syncEngine = await self.syncEngine
            if let localStatus = syncEngine.checkMigrationStatusLocal() {
                await self.handleMigrationStatus(localStatus, auth: auth)
                return
            }

            do {
                let status = try syncEngine.checkMigrationStatus(auth: auth)
                await self.handleMigrationStatus(status, auth: auth)
            } catch {
                await MainActor.run {
                    self.syncState = .error("Offline")
                }
            }
        }
    }

    private func handleMigrationStatus(_ status: MigrationState, auth: SyncAuth) async {
        switch status {
        case .inProgress:
            await performBatchedSync(auth: auth)
        case .notNeeded, .complete:
            performSyncWithAuth(auth: auth, showErrors: false, showSuccess: false)
        case .failed:
            await MainActor.run {
                self.syncState = .error("Migration failed")
            }
        }
    }

    private func performSync(showErrors: Bool, showSuccess: Bool) {
        reopenSyncStoresIfNeeded()
        guard let auth = buildSyncAuth() else {
            if showErrors {
                syncErrorMessage = "Sync failed: Sign in to sync"
            }
            return
        }
        performSyncWithAuth(auth: auth, showErrors: showErrors, showSuccess: showSuccess)
    }

    private func performSyncWithAuth(auth: SyncAuth, showErrors: Bool, showSuccess: Bool) {
        let log = logger
        syncState = .syncing
        log.info("Sync started")

        let syncEngine = self.syncEngine
        Task.detached { [weak self, log] in
            guard let self else { return }
            do {
                _ = try syncEngine.sync(auth: auth)
                log.info("Sync success")
                await MainActor.run {
                    self.syncState = .idle
                    self.reloadFromDb()
                    if showSuccess {
                        self.syncSuccessMessage = "Sync complete"
                    }
                }
            } catch {
                let message = syncErrorMessage(from: error)
                let needsReset = ChatRecovery.shouldResetFromMessage(message)
                let userMessage = needsReset
                    ? "\(message). Reset chat data to recover."
                    : message
                log.error("Sync failed", error, details: message)
                await MainActor.run {
                    self.syncState = .error(userMessage)
                    if showErrors {
                        self.syncErrorMessage = self.formatSyncErrorMessage(userMessage)
                    }
                }
            }
        }
    }

    private func performBatchedSync(auth: SyncAuth) async {
        let config = MigrationConfig(batchSize: 25, priority: .recentFirst)
        syncState = .migrating(processed: 0, total: 0)

        let syncEngine = syncEngine
        do {
            let handler = MigrationProgressHandler { [weak self] progress in
                Task { @MainActor in
                    self?.syncState = .migrating(processed: progress.processed, total: progress.total)
                }
            }
            try await Task.detached {
                _ = try syncEngine.syncWithProgress(auth: auth, config: config, callback: handler)
            }.value
            syncState = .idle
            reloadFromDb()
        } catch {
            let message = syncErrorMessage(from: error)
            syncState = .error(message)
            syncErrorMessage = formatSyncErrorMessage(message)
        }
    }

    func deleteAllData() async {
        await Task.detached { ChatDataCleaner.deleteAllData() }.value
        sessions = []
        messages = []
        currentSessionId = nil
        messageStore.removeAll()
        branchSelections.removeAll()
        childrenByParentCache.removeAll()
        attachmentDownloads = []
        currentSessionMissingAttachments = []
        syncState = .idle
        refreshAttachmentDownloadState()
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

        Task { @MainActor in
            let missing = await self.missingAttachments(for: sessionId)
            if !missing.isEmpty {
                self.queueMissingAttachments(for: sessionId, missing: missing)
                return
            }
            self.sendDraftMessage(trimmed: trimmed, attachments: attachments, sessionId: sessionId)
        }
    }

    private func sendDraftMessage(trimmed: String, attachments: [ChatAttachment], sessionId: UUID) {
        let parentId: UUID? = {
            if let editingId = editingMessageId {
                let existing = messageStore[sessionId]?.first { $0.id == editingId }
                return existing?.parentId
            }
            let childrenMap = childrenByParent(sessionId: sessionId)
            return buildSelectedPath(for: sessionId, childrenMap: childrenMap).last?.id
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

        logger.info(
            "Sent message",
            details: "id=\(messageId.uuidString) session=\(sessionId.uuidString) len=\(trimmed.count) attachments=\(attachments.count) edited=\(editingMessageId != nil)"
        )

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
        invalidateChildrenCache(for: sessionId)
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

    func confirmOverflowTrim() {
        guard let pendingOverflow else { return }
        guard let node = messageStore[pendingOverflow.sessionId]?.first(where: { $0.id == pendingOverflow.messageId }) else {
            cancelOverflowDialog()
            return
        }
        overflowBypassMessageId = pendingOverflow.messageId
        self.pendingOverflow = nil
        overflowAlert = nil
        startGeneration(for: node)
    }

    func cancelOverflowDialog() {
        pendingOverflow = nil
        overflowBypassMessageId = nil
        overflowAlert = nil
    }

    func refreshModelDownloadInfo() {
        let target = modelSettings.currentTarget()
        isModelDownloaded = provider.isModelDownloaded(target: target)
        if isModelDownloaded {
            modelDownloadSizeBytes = nil
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let size = await provider.estimatedDownloadSize(target: target)
            await MainActor.run {
                self.modelDownloadSizeBytes = size
            }
        }
    }

    func startModelDownload(userInitiated: Bool = true) {
        guard !isDownloading && !isGenerating else { return }
        if userInitiated {
            hasRequestedModelDownload = true
        }

        let target = modelSettings.currentTarget()
        let isDownloaded = provider.isModelDownloaded(target: target)
        if isDownloaded {
            isModelDownloaded = true
            modelDownloadSizeBytes = nil
            return
        }

        isDownloading = true
        modelDownloadLoggedStart = true
        logger.info("Model download started", details: "model=\(target.id)")

        modelDownloadTask?.cancel()
        modelDownloadTask = Task {
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
                if self.modelDownloadLoggedStart {
                    self.logger.error("Model download failed", error)
                    self.modelDownloadLoggedStart = false
                } else {
                    self.logger.error("Model load failed", error)
                }
                await MainActor.run {
                    self.downloadToast = DownloadToastState(
                        phase: .errorDownload,
                        percent: -1,
                        status: error.localizedDescription,
                        offerRetryDownload: true
                    )
                    self.isDownloading = false
                }
            }
        }
    }

    func autoStartModelDownloadIfNeeded() {
        guard !isDownloading && !isGenerating else { return }
        let target = modelSettings.currentTarget()
        let isDownloaded = provider.isModelDownloaded(target: target)
        isModelDownloaded = isDownloaded
        if !isDownloaded {
            return
        }
        modelDownloadSizeBytes = nil
        modelDownloadTask?.cancel()
        modelDownloadTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.provider.ensureModelReady(target: target) { progress in
                    Task { @MainActor in
                        self.handleProgress(progress)
                    }
                }
            } catch {
                if self.isCancellation(error) {
                    return
                }
                await MainActor.run {
                    self.downloadToast = DownloadToastState(
                        phase: .errorLoad,
                        percent: -1,
                        status: error.localizedDescription,
                        offerRetryDownload: true
                    )
                    self.isDownloading = false
                }
            }
        }
    }

    func cancelDownload() {
        resetGenerationState(stopRequested: true)
        modelDownloadTask?.cancel()
        modelDownloadTask = nil
        provider.cancelDownload()
        if modelDownloadLoggedStart {
            logger.info("Model download cancelled")
            modelDownloadLoggedStart = false
        }
        hasRequestedModelDownload = false
        refreshModelDownloadInfo()
    }

    func retryDownload() {
        startModelDownload(userInitiated: true)
    }

    func retryAssistantResponse(_ message: ChatMessage) {
        guard message.role == .assistant else { return }
        if isGenerating {
            stopGenerating()
        }
        guard let sessionId = currentSessionId else { return }
        guard let parent = messageStore[sessionId]?.first(where: { $0.id == message.id })?.parentId,
              let userNode = messageStore[sessionId]?.first(where: { $0.id == parent }) else {
            return
        }
        Task { @MainActor in
            let missing = await self.missingAttachments(for: sessionId)
            if !missing.isEmpty {
                self.queueMissingAttachments(for: sessionId, missing: missing)
                return
            }
            self.provider.resetContext()
            self.startGeneration(for: userNode)
            self.syncNow(showErrors: false)
        }
    }

    func changeBranch(for message: ChatMessage, delta: Int) {
        if isGenerating {
            stopGenerating()
        }
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

        logger.info("Session created", details: "id=\(sessionId.uuidString)")
        let session = ChatSession(id: sessionId, title: created?.title ?? "New chat", lastMessage: "", updatedAt: updatedAt)
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        messageStore[session.id] = []
        branchSelections[session.id] = [:]
        invalidateChildrenCache(for: session.id)
        refreshAttachmentDownloadState()
        return session.id
    }

    private func startGeneration(for userNode: MessageNode) {
        generationTask?.cancel()
        sessionSummaryTask?.cancel()
        stopRequested = false

        let target = modelSettings.currentTarget()
        let prompt = buildPrompt(text: userNode.text, attachments: userNode.attachments)
        let historySelection = buildHistorySelection(
            sessionId: userNode.sessionId,
            promptText: prompt.text,
            promptImageCount: prompt.imageFiles.count,
            currentMessageId: userNode.id,
            target: target
        )

        if historySelection.wasTrimmed && overflowBypassMessageId != userNode.id {
            pendingOverflow = PendingOverflow(sessionId: userNode.sessionId, messageId: userNode.id)
            overflowAlert = OverflowAlertState(
                inputTokens: historySelection.inputTokens,
                inputBudget: historySelection.inputBudget,
                contextLength: target.contextLength ?? 4096,
                maxOutput: target.maxTokens ?? 1024
            )
            return
        }

        overflowBypassMessageId = nil
        pendingOverflow = nil
        overflowAlert = nil

        let generationId = UUID()
        activeGenerationId = generationId
        activeGenerationSessionId = userNode.sessionId
        isGenerating = true
        isDownloading = false
        hasRequestedModelDownload = true
        streamingResponse = ""
        streamingParentId = userNode.id
        downloadToast = nil
        rebuildMessages(for: userNode.sessionId)

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

            let history = historySelection.messages
            let systemMessage = InferenceMessage(text: Self.systemPrompt, role: .system, hasAttachments: false)
            let messages = [systemMessage] + history + [InferenceMessage(text: prompt.text, role: .user, hasAttachments: !userNode.attachments.isEmpty)]

            let bufferLock = NSLock()
            var buffer = ""
            var tokenCount = 0
            let uiUpdateInterval: TimeInterval = 0.05
            var lastUiUpdate = Date.distantPast
            var pendingSnapshot: String?
            var updateWorkItem: DispatchWorkItem?

            let scheduleStreamingUpdate = {
                bufferLock.lock()
                if updateWorkItem != nil {
                    bufferLock.unlock()
                    return
                }
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    bufferLock.lock()
                    let snapshot = pendingSnapshot
                    pendingSnapshot = nil
                    updateWorkItem = nil
                    lastUiUpdate = Date()
                    bufferLock.unlock()
                    guard let snapshot else { return }
                    Task { @MainActor in
                        guard self.activeGenerationId == generationId else { return }
                        self.streamingResponse = snapshot
                    }
                }
                updateWorkItem = workItem
                bufferLock.unlock()
                DispatchQueue.main.asyncAfter(deadline: .now() + uiUpdateInterval, execute: workItem)
            }

            do {
                let summary = try await provider.generateChat(
                    target: target,
                    messages: messages,
                    imageFiles: prompt.imageFiles,
                    temperature: resolveTemperature(),
                    maxTokens: target.maxTokens ?? 1024,
                    onToken: { token in
                        let tokenEstimate = max(1, token.count / 4)
                        var snapshot = ""
                        var shouldUpdateNow = false

                        bufferLock.lock()
                        buffer.append(token)
                        tokenCount += tokenEstimate
                        snapshot = buffer
                        pendingSnapshot = snapshot
                        let now = Date()
                        shouldUpdateNow = now.timeIntervalSince(lastUiUpdate) >= uiUpdateInterval
                        if shouldUpdateNow {
                            lastUiUpdate = now
                            pendingSnapshot = nil
                            updateWorkItem?.cancel()
                            updateWorkItem = nil
                        }
                        bufferLock.unlock()

                        if shouldUpdateNow {
                            Task { @MainActor in
                                guard self.activeGenerationId == generationId else { return }
                                self.streamingResponse = snapshot
                            }
                        } else {
                            scheduleStreamingUpdate()
                        }
                    }
                )

                finishGeneration(parent: userNode, response: buffer, tokenCount: tokenCount, totalTimeMs: summary.totalTimeMs, interrupted: false, generationId: generationId)
            } catch {
                let wasCancelled = stopRequested || isCancellation(error)
                if activeGenerationId == generationId && !wasCancelled {
                    let details = "session=\(userNode.sessionId.uuidString) promptLen=\(prompt.text.count) responseLen=\(buffer.count) tokens=\(tokenCount)"
                    logger.error("Generation failed", error, details: details)
                    generationErrorMessage = "Response failed. Try again."
                }
                finishGeneration(parent: userNode, response: buffer, tokenCount: tokenCount, totalTimeMs: nil, interrupted: true, generationId: generationId)
            }
        }
    }

    private func finishGeneration(parent: MessageNode, response: String, tokenCount: Int, totalTimeMs: Int64?, interrupted: Bool, generationId: UUID) {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let isActiveGeneration = activeGenerationId == generationId
        if trimmed.isEmpty {
            if isActiveGeneration && !interrupted && generationErrorMessage == nil {
                let details = "session=\(parent.sessionId.uuidString) promptLen=\(parent.text.count)"
                logger.warning("Generation returned empty response", details: details)
                generationErrorMessage = "No response from model. Try again."
            }
        } else {
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
                logger.info("Message created", details: "id=\(assistantId.uuidString) session=\(parent.sessionId.uuidString) role=assistant")
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
                invalidateChildrenCache(for: parent.sessionId)
                updateSelection(for: parent.sessionId, parentId: parent.id, childId: assistant.id)
                updateSessionPreview(sessionId: parent.sessionId, preview: trimmed, date: assistant.timestamp)
            }
        }

        if isActiveGeneration {
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
        scheduleSessionSummary(for: parent.sessionId)
    }

    private func handleProgress(_ progress: InferenceDownloadProgress) {
        if progress.percent == -1 {
            if modelDownloadLoggedStart {
                logger.error("Model download failed", details: progress.status)
                modelDownloadLoggedStart = false
            }
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
            if modelDownloadLoggedStart {
                logger.info("Model download complete", details: progress.status)
                modelDownloadLoggedStart = false
            }
            downloadToast = DownloadToastState(phase: .complete, percent: 100, status: progress.status, offerRetryDownload: false)
            isDownloading = false
            isModelDownloaded = true
            modelDownloadSizeBytes = nil
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
            case .SyncInProgress:
                return "Sync already in progress"
            }
        }
        let description = error.localizedDescription
        if description.isEmpty {
            return String(describing: error)
        }
        return description
    }

    private func formatSyncErrorMessage(_ message: String) -> String {
        let normalized = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("sync already in progress") {
            return message
        }
        return "Sync failed: \(message)"
    }

    private func queueMissingAttachments(for sessionId: UUID, missing: [AttachmentDownloadItem]? = nil) {
        Task { @MainActor in
            let resolvedMissing: [AttachmentDownloadItem]
            if let missing {
                resolvedMissing = missing
            } else {
                resolvedMissing = await self.missingAttachments(for: sessionId)
            }

            guard !resolvedMissing.isEmpty else {
                self.refreshAttachmentDownloadState(missing: [])
                return
            }

            var updated = self.attachmentDownloads
            for item in resolvedMissing {
                if let existingIndex = updated.firstIndex(where: { $0.id == item.id }) {
                    if updated[existingIndex].status == AttachmentDownloadItem.Status.failed ||
                        updated[existingIndex].status == AttachmentDownloadItem.Status.canceled {
                        updated[existingIndex].status = AttachmentDownloadItem.Status.queued
                        updated[existingIndex].errorMessage = nil
                    }
                } else {
                    updated.append(item)
                }
            }

            self.attachmentDownloads = updated
            for item in resolvedMissing {
                if !self.attachmentDownloadQueue.contains(item.id) && self.attachmentDownloadTasks[item.id] == nil {
                    self.attachmentDownloadQueue.append(item.id)
                }
            }

            self.refreshAttachmentDownloadState(missing: resolvedMissing)
            self.startNextAttachmentDownloads()
        }
    }

    private func missingAttachments(for sessionId: UUID) async -> [AttachmentDownloadItem] {
        guard let nodes = messageStore[sessionId], !nodes.isEmpty else { return [] }
        let attachments = nodes.flatMap { $0.attachments }
        let existingDownloads = attachmentDownloads
        let attachmentsDir = attachmentsDir

        let result: (missing: [AttachmentDownloadItem], availableIds: Set<String>) = await Task.detached {
            var seen = Set<String>()
            var missing: [AttachmentDownloadItem] = []
            var availableIds = Set<String>()

            for attachment in attachments {
                let id = attachment.id.uuidString.lowercased()
                if seen.contains(id) { continue }
                seen.insert(id)
                let path = attachmentsDir.appendingPathComponent(id).path
                if FileManager.default.fileExists(atPath: path) {
                    availableIds.insert(id)
                    continue
                }
                let existing = existingDownloads.first { $0.id == id }
                let status = existing?.status ?? AttachmentDownloadItem.Status.queued
                missing.append(AttachmentDownloadItem(
                    id: id,
                    sessionId: sessionId,
                    name: attachment.name,
                    size: attachment.size,
                    status: status,
                    errorMessage: existing?.errorMessage
                ))
            }

            return (missing, availableIds)
        }.value

        if !result.availableIds.isEmpty {
            for id in result.availableIds {
                attachmentDownloadTasks[id]?.cancel()
                attachmentDownloadTasks[id] = nil
            }
            attachmentDownloadQueue.removeAll { result.availableIds.contains($0) }
            attachmentDownloads.removeAll { result.availableIds.contains($0.id) }
        }

        return result.missing
    }

    private func startNextAttachmentDownloads() {
        reopenSyncStoresIfNeeded()
        guard attachmentDownloadTasks.count < maxAttachmentDownloads else { return }
        guard let auth = buildSyncAuth() else { return }

        let syncEngine = self.syncEngine
        while attachmentDownloadTasks.count < maxAttachmentDownloads, !attachmentDownloadQueue.isEmpty {
            let id = attachmentDownloadQueue.removeFirst()
            guard let index = attachmentDownloads.firstIndex(where: { $0.id == id }) else { continue }
            if attachmentDownloads[index].status == AttachmentDownloadItem.Status.canceled ||
                attachmentDownloads[index].status == AttachmentDownloadItem.Status.completed {
                continue
            }
            let sessionId = attachmentDownloads[index].sessionId
            attachmentDownloads[index].status = AttachmentDownloadItem.Status.downloading

            let task = Task.detached { [weak self] in
                guard let self else { return }
                do {
                    _ = try syncEngine.downloadAttachment(
                        attachmentId: id,
                        sessionUuid: sessionId.uuidString,
                        auth: auth
                    )
                    await MainActor.run {
                        self.updateAttachmentDownloadStatus(id: id, status: AttachmentDownloadItem.Status.completed, errorMessage: nil)
                    }
                } catch {
                    let message = self.syncErrorMessage(from: error)
                    await MainActor.run {
                        self.updateAttachmentDownloadStatus(id: id, status: AttachmentDownloadItem.Status.failed, errorMessage: message)
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
            if attachmentDownloads[index].status != AttachmentDownloadItem.Status.canceled {
                attachmentDownloads[index].status = status
                attachmentDownloads[index].errorMessage = status == AttachmentDownloadItem.Status.failed ? errorMessage : nil
            }
        }
        attachmentDownloadTasks[id] = nil
        refreshAttachmentDownloadState()
        startNextAttachmentDownloads()
    }

    private func refreshAttachmentDownloadState(missing: [AttachmentDownloadItem]? = nil) {
        guard let sessionId = currentSessionId else {
            currentSessionMissingAttachments = []
            return
        }

        if let missing {
            currentSessionMissingAttachments = missing
            return
        }

        Task { @MainActor in
            self.currentSessionMissingAttachments = await self.missingAttachments(for: sessionId)
        }
    }

    func cancelAttachmentDownload(_ id: String) {
        if let task = attachmentDownloadTasks[id] {
            task.cancel()
            attachmentDownloadTasks[id] = nil
        }
        if let index = attachmentDownloads.firstIndex(where: { $0.id == id }) {
            attachmentDownloads[index].status = AttachmentDownloadItem.Status.canceled
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

    private static func buildSessions(
        from loaded: [LlmChatSession],
        chatDb: LlmChatDb,
        summaries: [String: String]
    ) -> [ChatSession] {
        loaded.compactMap { session in
            guard let id = UUID(uuidString: session.uuid) else { return nil }
            let messages = (try? chatDb.getMessages(sessionUuid: session.uuid)) ?? []
            let sortedMessages = messages.sorted { $0.createdAtUs < $1.createdAtUs }
            let firstUserMessage = sortedMessages.first(where: { $0.sender == .selfUser })?.text ?? ""
            let lastMessage = sortedMessages.last?.text ?? ""
            let summary = summaries[session.uuid.lowercased()]
            let isPlaceholderTitle = session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                session.title.caseInsensitiveCompare("New chat") == .orderedSame
            let seedTitle = summary ?? (isPlaceholderTitle ? firstUserMessage : session.title)
            let title = Self.sessionTitle(from: seedTitle, fallback: session.title)
            return ChatSession(
                id: id,
                title: title,
                lastMessage: lastMessage,
                updatedAt: Date(timeIntervalSince1970: Double(session.updatedAtUs) / 1_000_000.0)
            )
        }
    }

    private func reloadFromDb() {
        reloadTask?.cancel()
        reopenSyncStoresIfNeeded()
        let chatDb = chatDb
        let summaries = sessionSummaries
        let selected = currentSessionId

        reloadTask = Task.detached { [weak self, chatDb, summaries, selected] in
            let loaded = (try? chatDb.listSessions()) ?? []
            let refreshed = Self.buildSessions(from: loaded, chatDb: chatDb, summaries: summaries)

            let resolved = selected.flatMap { id in
                refreshed.first(where: { $0.id == id })?.id
            } ?? (selected == nil ? nil : refreshed.first?.id)

            if Task.isCancelled { return }

            await MainActor.run {
                guard let self else { return }
                if Task.isCancelled { return }

                self.sessions = refreshed
                self.currentSessionId = resolved
                self.messages = []
                self.messageStore = [:]
                self.branchSelections = [:]
                self.childrenByParentCache = [:]

                for session in refreshed {
                    self.messageStore[session.id] = []
                    self.branchSelections[session.id] = [:]
                }

                if let current = resolved {
                    self.loadMessagesFromDb(for: current)
                } else {
                    self.refreshAttachmentDownloadState()
                }
            }
        }
    }

    private func loadMessagesFromDb(for sessionId: UUID) {
        reopenSyncStoresIfNeeded()
        if messageStore[sessionId] == nil {
            messageStore[sessionId] = []
            branchSelections[sessionId] = [:]
        }

        let chatDb = chatDb
        let attachmentsDir = attachmentsDir

        Task.detached { [weak self, chatDb, attachmentsDir] in
            guard let self else { return }

            let rawMessages = (try? chatDb.getMessages(sessionUuid: sessionId.uuidString)) ?? []

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

            await MainActor.run {
                guard self.messageStore[sessionId] != nil else { return }
                self.messageStore[sessionId] = nodes
                // Branch selection is computed in-memory.
                self.branchSelections[sessionId] = [:]
                self.invalidateChildrenCache(for: sessionId)
                if self.currentSessionId == sessionId {
                    self.rebuildMessages(for: sessionId)
                    self.queueMissingAttachments(for: sessionId)
                }
            }
        }
    }

    private func rebuildMessages(for sessionId: UUID) {
        let childrenMap = childrenByParent(sessionId: sessionId)
        let path = buildSelectedPath(for: sessionId, childrenMap: childrenMap)
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

    private func buildSelectedPath(for sessionId: UUID, childrenMap: [UUID: [MessageNode]]) -> [MessageNode] {
        guard let nodes = messageStore[sessionId], !nodes.isEmpty else { return [] }
        let byId = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
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

    private func invalidateChildrenCache(for sessionId: UUID) {
        childrenByParentCache[sessionId] = nil
    }

    private func childrenByParent(sessionId: UUID) -> [UUID: [MessageNode]] {
        if let cached = childrenByParentCache[sessionId] {
            return cached
        }
        var map: [UUID: [MessageNode]] = [:]
        guard let nodes = messageStore[sessionId] else { return map }
        let byId = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        for node in nodes {
            let parent = node.parentId.flatMap { byId[$0] != nil ? $0 : nil } ?? rootId
            map[parent, default: []].append(node)
        }
        childrenByParentCache[sessionId] = map
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
            let isPlaceholderTitle = session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                session.title.caseInsensitiveCompare("New chat") == .orderedSame
            if isPlaceholderTitle {
                let updatedTitle = Self.sessionTitle(from: preview, fallback: session.title)
                if updatedTitle != session.title {
                    _ = try? chatDb.updateSessionTitle(uuid: sessionId.uuidString, title: updatedTitle)
                }
                updated.title = updatedTitle
            }
            updated.lastMessage = preview
            updated.updatedAt = date
            return updated
        }
    }

    private func scheduleSessionSummary(for sessionId: UUID) {
        sessionSummaryTask?.cancel()
        let summaryKey = sessionSummaryKey(sessionId)
        guard sessionSummaries[summaryKey] == nil else { return }
        guard let summaryInput = buildSessionSummaryInput(sessionId: sessionId) else { return }
        let existingSummary = sessionSummaries[summaryKey]
        let target = modelSettings.currentTarget()
        let provider = provider

        sessionSummaryTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 200_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            let summary = await Self.generateSessionSummary(
                input: summaryInput.text,
                fallback: summaryInput.fallback,
                existingSummary: existingSummary,
                provider: provider,
                target: target
            )
            guard let summary else { return }

            await MainActor.run {
                self.applySessionSummary(sessionId: sessionId, summary: summary)
            }
        }
    }

    private func buildSessionSummaryInput(sessionId: UUID) -> (text: String, fallback: String)? {
        guard let nodes = messageStore[sessionId], !nodes.isEmpty else { return nil }
        let sorted = nodes.sorted(by: { $0.timestamp < $1.timestamp })
        guard let firstUser = sorted.first(where: { $0.role == .user }) else { return nil }
        let input = "User: \(firstUser.text)"
        let fallback = Self.summarizeQuestion(firstUser.text)
        return (text: input, fallback: fallback)
    }

    private func applySessionSummary(sessionId: UUID, summary: String) {
        let sanitized = Self.sessionTitle(from: summary, fallback: "New chat")
        guard !sanitized.isEmpty else { return }
        let summaryKey = sessionSummaryKey(sessionId)
        if sessionSummaries[summaryKey] == sanitized { return }
        sessionSummaries[summaryKey] = sanitized
        persistSessionSummaries()
        _ = try? chatDb.updateSessionTitle(uuid: sessionId.uuidString, title: sanitized)
        sessions = sessions.map { session in
            guard session.id == sessionId else { return session }
            var updated = session
            updated.title = sanitized
            return updated
        }
    }

    private func persistSessionSummaries() {
        guard let data = try? JSONEncoder().encode(sessionSummaries) else { return }
        UserDefaults.standard.set(data, forKey: Self.sessionSummaryStoreKey)
    }

    private func sessionSummaryKey(_ id: UUID) -> String {
        id.uuidString.lowercased()
    }

    private func sessionSummaryKey(_ id: String) -> String {
        id.lowercased()
    }

    private static func loadSessionSummaries() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: Self.sessionSummaryStoreKey) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    private static func summarizeQuestion(_ text: String) -> String {
        let cleaned = sanitizeTitleText(text)
        guard !cleaned.isEmpty else { return "" }
        let words = cleaned.split(separator: " ").map {
            String($0).trimmingCharacters(in: .punctuationCharacters)
        }.filter { !$0.isEmpty }
        guard !words.isEmpty else { return "" }
        let summaryWords = words.prefix(Self.sessionSummaryMaxWords)
        return summaryWords.joined(separator: " ")
    }

    private static func sanitizeTitleText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "[\\r\\n\\t]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sessionTitle(from text: String, fallback: String = "New chat") -> String {
        let trimmed = sanitizeTitleText(text)
        guard !trimmed.isEmpty else { return fallback }
        if trimmed.count <= Self.sessionTitleMaxLength {
            return trimmed
        }
        let prefix = trimmed.prefix(Self.sessionTitleMaxLength)
        return String(prefix).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private static func generateSessionSummary(
        input: String,
        fallback: String,
        existingSummary: String?,
        provider: InferenceRsProvider,
        target: InferenceModelTarget
    ) async -> String? {
        if let existingSummary, !existingSummary.isEmpty { return nil }
        let cleanedInput = sanitizeTitleText(input)
        guard !cleanedInput.isEmpty else { return sessionTitle(from: fallback, fallback: fallback) }

        let messages = [
            InferenceMessage(text: sessionSummarySystemPrompt, role: .system, hasAttachments: false),
            InferenceMessage(text: cleanedInput, role: .user, hasAttachments: false)
        ]

        let bufferLock = NSLock()
        var buffer = ""

        do {
            _ = try await provider.generateChat(
                target: target,
                messages: messages,
                imageFiles: [],
                temperature: 0.2,
                maxTokens: 64
            ) { token in
                bufferLock.lock()
                buffer.append(token)
                bufferLock.unlock()
            }
        } catch {
            let fallbackSummary = summarizeQuestion(fallback)
            return fallbackSummary.isEmpty ? nil : sessionTitle(from: fallbackSummary, fallback: fallback)
        }

        let raw = sanitizeTitleText(buffer)
        guard !raw.isEmpty else { return sessionTitle(from: fallback, fallback: fallback) }
        let words = raw.split(separator: " ").map { String($0) }.filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        let summaryWords = words.prefix(Self.sessionSummaryMaxWords)
        let summary = summaryWords.joined(separator: " ")
        return sessionTitle(from: summary, fallback: fallback)
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

    private struct HistorySelection {
        let messages: [InferenceMessage]
        let inputTokens: Int
        let inputBudget: Int
        let wasTrimmed: Bool
    }

    private struct PendingOverflow {
        let sessionId: UUID
        let messageId: UUID
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

    private func buildHistorySelection(
        sessionId: UUID,
        promptText: String,
        promptImageCount: Int,
        currentMessageId: UUID,
        target: InferenceModelTarget
    ) -> HistorySelection {
        let childrenMap = childrenByParent(sessionId: sessionId)
        let path = buildSelectedPath(for: sessionId, childrenMap: childrenMap)
        let historyMessages = path.prefix { $0.id != currentMessageId }

        let contextSize: Int = target.contextLength ?? 4096
        let maxTokens: Int = target.maxTokens ?? 1024
        let inputBudget = max(0, contextSize - maxTokens - Self.overflowSafetyTokens)
        let systemTokens = estimateTokens(Self.systemPrompt)
        let promptTokens = estimatePromptTokens(promptText: promptText, imageCount: promptImageCount)
        let historyTokens = historyMessages.reduce(0) { total, node in
            total + estimateTokens(historyText(node))
        }
        let inputTokens = systemTokens + promptTokens + historyTokens
        var remaining = inputBudget - systemTokens - promptTokens

        if remaining <= 0 || historyMessages.isEmpty {
            return HistorySelection(messages: [], inputTokens: inputTokens, inputBudget: inputBudget, wasTrimmed: inputTokens > inputBudget)
        }

        var selected: [InferenceMessage] = []
        for node in historyMessages.reversed() {
            let text = historyText(node)
            let cost = estimateTokens(text)
            if cost <= remaining {
                selected.append(InferenceMessage(text: text, role: node.role == .user ? .user : .assistant, hasAttachments: !node.attachments.isEmpty))
                remaining -= cost
            } else {
                break
            }
        }

        return HistorySelection(messages: selected.reversed(), inputTokens: inputTokens, inputBudget: inputBudget, wasTrimmed: inputTokens > inputBudget)
    }

    private func historyText(_ node: MessageNode) -> String {
        var text = node.text
        if node.role == .assistant {
            if let regex = ChatMessageTagRegex.think {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            } else {
                text = text.replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
            }
            if let regex = ChatMessageTagRegex.todoList {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            } else {
                text = text.replacingOccurrences(of: "<todo_list>[\\s\\S]*?</todo_list>", with: "", options: .regularExpression)
            }
        } else if !node.attachments.isEmpty {
            text += "\n\n[\(node.attachments.count) attachments attached]"
        }
        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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

    private func estimateImageTokens(_ imageCount: Int) -> Int {
        imageCount * Self.imageTokenEstimate
    }

    private func estimatePromptTokens(promptText: String, imageCount: Int) -> Int {
        estimateTokens(promptText) + estimateImageTokens(imageCount)
    }

    private func resolveTemperature() -> Float {
        let value = Float(modelSettings.temperature.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        let resolved = value.map { max(0, $0) } ?? Self.defaultTemperature
        return min(max(resolved, 0.35), 0.7)
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
#else
@MainActor
final class ChatViewModel: ObservableObject {
    init() {}
}
#endif
