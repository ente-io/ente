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
    var isUploading: Bool

    init(id: UUID = UUID(), name: String, size: Int64, kind: Kind, isUploading: Bool = false) {
        self.id = id
        self.name = name
        self.size = size
        self.kind = kind
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
    @Published var isGenerating: Bool = false
    @Published var isDownloading: Bool = false
    @Published var isProcessingAttachments: Bool = false
    @Published var draftText: String = ""
    @Published var draftAttachments: [ChatAttachment] = []
    @Published var editingMessageId: UUID?
    @Published var downloadToast: DownloadToastState?

    private var streamingTask: Task<Void, Never>?

    init() {
        let sampleSessions = [
            ChatSession(title: "Daily brief", lastMessage: "Summarize today's highlights", updatedAt: Date()),
            ChatSession(title: "Travel notes", lastMessage: "Itinerary draft", updatedAt: Date().addingTimeInterval(-3600 * 6)),
            ChatSession(title: "Project outline", lastMessage: "Architecture review", updatedAt: Date().addingTimeInterval(-3600 * 30)),
            ChatSession(title: "Weekend ideas", lastMessage: "Check local events", updatedAt: Date().addingTimeInterval(-3600 * 80))
        ]

        self.sessions = sampleSessions
        self.currentSessionId = sampleSessions.first?.id

        self.messages = [
            ChatMessage(
                role: .assistant,
                text: "Welcome to ensu. Here's a snapshot of what this UI supports.\n\n<think>We should greet the user and highlight the key controls so they can explore the UI components.</think>\n\n<todo_list>{\"title\":\"Getting started\",\"status\":\"Optional\",\"items\":[\"Open the drawer to switch chats\",\"Try editing a user message\",\"Preview markdown and code blocks\"]}</todo_list>\n\n## Markdown preview\nYou can paste snippets here and we'll render headings, lists, and code blocks.\n\n```swift\nstruct HelloWorld: View {\n    var body: some View {\n        Text(\"Hello, Ensu\")\n    }\n}\n```"
            ),
            ChatMessage(
                role: .user,
                text: "Share the next steps for our onboarding flow.",
                attachments: [
                    ChatAttachment(name: "brief.pdf", size: 482_000, kind: .document),
                    ChatAttachment(name: "flow.png", size: 221_000, kind: .image)
                ],
                branchCount: 3
            ),
            ChatMessage(
                role: .assistant,
                text: "Absolutely. I can draft a step-by-step onboarding doc or outline the key user journeys. Let me know which format you prefer.",
                tokensPerSecond: 3.2
            )
        ]
    }

    var currentSession: ChatSession? {
        guard let currentSessionId else { return nil }
        return sessions.first { $0.id == currentSessionId }
    }

    func startNewSession() {
        streamingTask?.cancel()
        isGenerating = false
        streamingResponse = ""
        draftText = ""
        draftAttachments = []

        let session = ChatSession(title: "New chat", lastMessage: "", updatedAt: Date())
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        messages = []
    }

    func selectSession(_ session: ChatSession) {
        streamingTask?.cancel()
        isGenerating = false
        streamingResponse = ""
        currentSessionId = session.id
        messages = [
            ChatMessage(role: .assistant, text: "Loading \(session.title)…")
        ]
    }

    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if currentSessionId == session.id {
            currentSessionId = sessions.first?.id
            messages = []
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

    func addAttachment(kind: ChatAttachment.Kind) {
        guard !isGenerating && !isDownloading else { return }
        isProcessingAttachments = true

        let name = kind == .image ? "photo.png" : "document.pdf"
        let size = Int64.random(in: 120_000...980_000)
        let attachment = ChatAttachment(name: name, size: size, kind: kind, isUploading: false)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            draftAttachments.append(attachment)
            isProcessingAttachments = false
        }
    }

    func removeAttachment(_ attachment: ChatAttachment) {
        draftAttachments.removeAll { $0.id == attachment.id }
    }

    func sendDraft() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let editingMessageId, let index = messages.firstIndex(where: { $0.id == editingMessageId }) {
            messages[index].text = trimmed
            messages[index].attachments = draftAttachments
            self.editingMessageId = nil
        } else {
            messages.append(
                ChatMessage(
                    role: .user,
                    text: trimmed,
                    attachments: draftAttachments
                )
            )
        }

        updateCurrentSession(lastMessage: trimmed)
        draftText = ""
        draftAttachments = []
        startStreamingResponse(for: trimmed)
    }

    func stopGenerating() {
        streamingTask?.cancel()
        streamingTask = nil

        guard isGenerating else { return }
        isGenerating = false

        let responseText = streamingResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !responseText.isEmpty {
            messages.append(
                ChatMessage(
                    role: .assistant,
                    text: responseText,
                    isInterrupted: true
                )
            )
        }
        streamingResponse = ""
    }

    func retryAssistantResponse(_ message: ChatMessage) {
        guard message.role == .assistant else { return }
        startStreamingResponse(for: message.text)
    }

    func changeBranch(for message: ChatMessage, delta: Int) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        let current = messages[index].branchIndex
        let total = messages[index].branchCount
        let next = max(1, min(total, current + delta))
        messages[index].branchIndex = next
    }

    func simulateDownload() {
        downloadToast = DownloadToastState(phase: .downloading, percent: 0, status: "Preparing…", offerRetryDownload: false)
        isDownloading = true

        Task { @MainActor in
            for step in stride(from: 5, through: 100, by: 5) {
                try? await Task.sleep(nanoseconds: 150_000_000)
                downloadToast?.percent = step
                if step < 100 {
                    downloadToast?.phase = .downloading
                    downloadToast?.status = "Downloading model…"
                } else {
                    downloadToast?.phase = .loading
                    downloadToast?.status = "Loading model…"
                }
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            downloadToast?.phase = .complete
            downloadToast?.status = "Model ready"
            isDownloading = false

            try? await Task.sleep(nanoseconds: 800_000_000)
            downloadToast = nil
        }
    }

    private func startStreamingResponse(for prompt: String) {
        streamingTask?.cancel()
        streamingResponse = ""
        isGenerating = true

        let response = "Here is a draft response for: \(prompt).\n\n- Keep the tone warm\n- Highlight the next action\n- Offer a follow-up question"
        let words = response.split(separator: " ")

        streamingTask = Task { @MainActor in
            for word in words {
                if Task.isCancelled { return }
                streamingResponse += (streamingResponse.isEmpty ? "" : " ") + word
                try? await Task.sleep(nanoseconds: 120_000_000)
            }

            finishStreamingResponse()
        }
    }

    private func finishStreamingResponse() {
        streamingTask = nil
        let finalText = streamingResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalText.isEmpty else {
            isGenerating = false
            return
        }

        messages.append(
            ChatMessage(
                role: .assistant,
                text: finalText,
                tokensPerSecond: Double.random(in: 2.6...3.8)
            )
        )
        streamingResponse = ""
        isGenerating = false
        updateCurrentSession(lastMessage: finalText)
    }

    private func updateCurrentSession(lastMessage: String) {
        guard let currentSessionId, let index = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
        sessions[index].lastMessage = lastMessage
        sessions[index].updatedAt = Date()
    }
}
