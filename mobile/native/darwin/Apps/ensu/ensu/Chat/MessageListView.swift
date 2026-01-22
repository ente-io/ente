#if canImport(EnteCore)
import SwiftUI
import QuickLook
#if os(iOS)
import UIKit
#endif

struct MessageListView: View {
    let messages: [ChatMessage]
    let streamingResponse: String
    let streamingParentId: UUID?
    let isGenerating: Bool
    let keyboardHeight: CGFloat
    let emptyStateTitle: String
    let emptyStateSubtitle: String?
    let onEdit: (ChatMessage) -> Void
    let onCopy: (ChatMessage) -> Void
    let onRetry: (ChatMessage) -> Void
    let onBranchChange: (ChatMessage, Int) -> Void

    @State private var isAtBottom = true
    @State private var autoScrollEnabled = true
    @State private var previewItem: AttachmentPreviewItem?
    @State private var lastHapticLength = 0
    @State private var wasAtBottomBeforeKeyboard = false
    #if os(iOS)
    @State private var haptic = UIImpactFeedbackGenerator(style: .medium)
    #endif

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: EnsuSpacing.lg) {
                        if messages.isEmpty && !isGenerating {
                            VStack(spacing: EnsuSpacing.sm) {
                                Text(emptyStateTitle)
                                    .font(EnsuTypography.large)
                                    .foregroundStyle(EnsuColor.textPrimary)
                                if let emptyStateSubtitle {
                                    Text(emptyStateSubtitle)
                                        .font(EnsuTypography.body)
                                        .foregroundStyle(EnsuColor.textMuted)
                                }
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: proxy.size.height * 0.6)
                        }

                        ForEach(messages) { message in
                            if message.role == .user {
                                UserMessageBubbleView(
                                    message: message,
                                    onEdit: { onEdit(message) },
                                    onCopy: { onCopy(message) },
                                    onBranchChange: { delta in onBranchChange(message, delta) },
                                    onOpenAttachment: openAttachment
                                )
                                .id(message.id)
                            } else {
                                AssistantMessageBubbleView(
                                    message: message,
                                    onCopy: { onCopy(message) },
                                    onRetry: { onRetry(message) },
                                    onBranchChange: { delta in onBranchChange(message, delta) },
                                    onOpenAttachment: openAttachment
                                )
                                .id(message.id)
                            }

                            if isGenerating, streamingParentId == message.id {
                                StreamingBubbleView(text: streamingResponse)
                                    .id("streaming-\(message.id.uuidString)")
                            }
                        }

                        if isGenerating, streamingParentId == nil {
                            StreamingBubbleView(text: streamingResponse)
                                .id("streaming")
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: BottomOffsetKey.self, value: geo.frame(in: .named("scroll")).maxY)
                                }
                            )
                    }
                    .padding(.horizontal, EnsuSpacing.pageHorizontal)
                    .padding(.vertical, EnsuSpacing.lg)
                }
                .coordinateSpace(name: "scroll")
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        autoScrollEnabled = false
                    }
                )
                .onPreferenceChange(BottomOffsetKey.self) { value in
                    let threshold: CGFloat = 24
                    isAtBottom = value < proxy.size.height + threshold
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(scrollProxy)
                }
                .onChange(of: streamingResponse) { newValue in
                    #if os(iOS)
                    if isGenerating {
                        let length = newValue.count
                        if length > lastHapticLength {
                            haptic.impactOccurred()
                            haptic.prepare()
                            lastHapticLength = length
                        }
                    }
                    #endif
                    scrollToBottom(scrollProxy)
                }
                .onChange(of: keyboardHeight) { newValue in
                    if newValue > 0 {
                        wasAtBottomBeforeKeyboard = isAtBottom
                    }
                    if wasAtBottomBeforeKeyboard {
                        autoScrollEnabled = true
                        scrollToBottom(scrollProxy, force: true)
                    }
                    if newValue == 0 {
                        wasAtBottomBeforeKeyboard = false
                    }
                }
                .onChange(of: isGenerating) { newValue in
                    if newValue {
                        autoScrollEnabled = true
                        lastHapticLength = 0
                        #if os(iOS)
                        haptic.prepare()
                        #endif
                        scrollToBottom(scrollProxy, force: true)
                    }
                }
                .onChange(of: isAtBottom) { newValue in
                    if newValue && isGenerating {
                        autoScrollEnabled = true
                        scrollToBottom(scrollProxy, force: true)
                    }
                }
                .onAppear {
                    #if os(iOS)
                    haptic.prepare()
                    #endif
                    scrollToBottom(scrollProxy, force: true)
                }
            }
        }
        .sheet(item: $previewItem) { item in
            QuickLookPreview(url: item.url)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, force: Bool = false) {
        guard force || (autoScrollEnabled && isAtBottom) else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    private func openAttachment(_ attachment: ChatAttachment) {
        guard let url = attachment.url else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        previewItem = AttachmentPreviewItem(url: url)
    }
}

private struct BottomOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct AttachmentPreviewItem: Identifiable {
    let url: URL
    var id: String { url.path }
}

#if os(iOS)
private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
#elseif os(macOS)
private struct QuickLookPreview: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)
        view.autostarts = true
        view.previewItem = url as NSURL
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as NSURL
    }
}
#endif

private struct UserMessageBubbleView: View {
    let message: ChatMessage
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onBranchChange: (Int) -> Void
    let onOpenAttachment: (ChatAttachment) -> Void

    var body: some View {
        let bubbleShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        HStack(alignment: .bottom) {
            Spacer(minLength: EnsuSpacing.messageBubbleInset)

            VStack(alignment: .trailing, spacing: EnsuSpacing.sm) {
                VStack(alignment: .trailing, spacing: EnsuSpacing.sm) {
                    if !message.attachments.isEmpty {
                        FlowLayout(spacing: EnsuSpacing.sm) {
                            ForEach(message.attachments) { attachment in
                                AttachmentChip(
                                    name: attachment.name,
                                    size: attachment.formattedSize,
                                    icon: attachment.iconName,
                                    isUploading: attachment.isUploading
                                )
                                .onTapGesture {
                                    hapticTap()
                                    onOpenAttachment(attachment)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Text(message.text)
                        .font(EnsuTypography.message)
                        .foregroundStyle(EnsuColor.userMessageText)
                        .lineSpacing(EnsuLineHeight.spacing(fontSize: 15, lineHeight: 1.7))
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                .padding(EnsuSpacing.md)
                .background(EnsuColor.border.opacity(0.2))
                .clipShape(bubbleShape)
                #if os(iOS)
                .contextMenu {
                    Button("Edit") {
                        hapticTap()
                        onEdit()
                    }
                    Button("Copy") {
                        hapticTap()
                        onCopy()
                    }
                }
                #endif

                HStack(spacing: EnsuSpacing.sm) {
                    Spacer()
                    if message.branchCount > 1 {
                        BranchSwitcherView(
                            currentIndex: message.branchIndex,
                            totalCount: message.branchCount,
                            onPrevious: { onBranchChange(-1) },
                            onNext: { onBranchChange(1) }
                        )
                    }
                    TimestampView(date: message.timestamp)
                }
            }
        }
    }
}

private struct AssistantMessageBubbleView: View {
    let message: ChatMessage
    let onCopy: () -> Void
    let onRetry: () -> Void
    let onBranchChange: (Int) -> Void
    let onOpenAttachment: (ChatAttachment) -> Void

    var body: some View {
        let bubbleShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                    AssistantMessageRenderer(text: message.text, isStreaming: false, storageId: message.id.uuidString)

                    if message.isInterrupted {
                        Text("Interrupted")
                            .font(EnsuTypography.small)
                            .italic()
                            .foregroundStyle(EnsuColor.textMuted)
                    }
                }
                .padding(EnsuSpacing.md)
                .background(EnsuColor.border.opacity(0.2))
                .clipShape(bubbleShape)
                #if os(iOS)
                .contextMenu {
                    Button("Copy") {
                        hapticTap()
                        onCopy()
                    }
                    Button("Retry") {
                        hapticMedium()
                        onRetry()
                    }
                }
                #endif

                HStack(spacing: EnsuSpacing.sm) {
                    TimestampView(date: message.timestamp)
                    if message.branchCount > 1 {
                        BranchSwitcherView(
                            currentIndex: message.branchIndex,
                            totalCount: message.branchCount,
                            onPrevious: { onBranchChange(-1) },
                            onNext: { onBranchChange(1) }
                        )
                    }
                }
            }

            Spacer(minLength: EnsuSpacing.messageBubbleInset)
        }
    }
}

private struct StreamingBubbleView: View {
    let text: String

    @State private var cursorOpacity: Double = 1

    var body: some View {
        let bubbleShape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LoadingDotsView()
                    } else {
                        HStack(alignment: .bottom, spacing: 4) {
                            AssistantMessageRenderer(text: text, isStreaming: true, storageId: UUID().uuidString)
                            Rectangle()
                                .fill(EnsuColor.accent)
                                .frame(width: 2, height: 18)
                                .opacity(cursorOpacity)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.53).repeatForever(autoreverses: true)) {
                                        cursorOpacity = 0
                                    }
                                }
                        }
                    }
                }
                .padding(EnsuSpacing.md)
                .background(EnsuColor.border.opacity(0.2))
                .clipShape(bubbleShape)
            }

            Spacer(minLength: EnsuSpacing.messageBubbleInset)
        }
    }
}

private struct LoadingDotsView: View {
    @State private var phrase: String = LoadingDotsView.randomPhrase()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let phase = Int(context.date.timeIntervalSinceReferenceDate * 2) % 3
            Text(phrase + dots(for: phase))
                .font(EnsuTypography.message)
                .foregroundStyle(EnsuColor.textMuted)
        }
    }

    private static let loadingPhraseVerbs = [
        "Generating",
        "Thinking through",
        "Assembling",
        "Drafting",
        "Composing",
        "Crunching",
        "Exploring",
        "Piecing together",
        "Reviewing",
        "Organizing",
        "Synthesizing",
        "Sketching",
        "Refining",
        "Shaping"
    ]

    private static let loadingPhraseTargets = [
        "your reply",
        "an answer",
        "ideas",
        "context",
        "details",
        "the response",
        "the next steps",
        "a solution",
        "the summary",
        "insights",
        "the draft",
        "the explanation"
    ]

    private static func randomPhrase() -> String {
        let verb = loadingPhraseVerbs.randomElement() ?? "Generating"
        let target = loadingPhraseTargets.randomElement() ?? "your reply"
        return "\(verb) \(target)"
    }

    private func dots(for phase: Int) -> String {
        switch phase {
        case 0: return "."
        case 1: return ".."
        default: return "..."
        }
    }
}

private struct TimestampView: View {
    let date: Date

    var body: some View {
        Text(Self.formatter.string(from: date))
            .font(EnsuTypography.mini)
            .foregroundStyle(EnsuColor.textMuted)
            .monospacedDigit()
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

private struct BranchSwitcherView: View {
    let currentIndex: Int
    let totalCount: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        if totalCount > 1 {
            HStack(spacing: EnsuSpacing.sm) {
                TextActionButton(text: "<", action: onPrevious)
                    .disabled(currentIndex <= 1)
                Text(String(format: "%2d/%d", currentIndex, totalCount))
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
                    .monospacedDigit()
                TextActionButton(text: ">", action: onNext)
                    .disabled(currentIndex >= totalCount)
            }
        }
    }
}

struct AssistantMessageRenderer: View {
    let text: String
    let isStreaming: Bool
    let storageId: String

    var body: some View {
        let parsed = ParsedMessage(text: text)

        VStack(alignment: .leading, spacing: EnsuSpacing.lg) {
            if let think = parsed.thinkContent {
                ThinkSectionView(content: think, isStreaming: isStreaming, storageId: storageId)
            }

            ForEach(parsed.todoBlocks) { block in
                TodoListCardView(title: block.title, status: block.status, items: block.items)
            }

            if !parsed.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                MarkdownView(markdown: parsed.markdown)
            }
        }
    }
}

private struct ParsedMessage {
    struct TodoBlock: Identifiable {
        let id = UUID()
        let title: String
        let status: String?
        let items: [String]
    }

    let thinkContent: String?
    let todoBlocks: [TodoBlock]
    let markdown: String

    init(text: String) {
        var remaining = text
        var think: String?
        var todos: [TodoBlock] = []

        if let thinkRange = ParsedMessage.extractTag(named: "think", from: remaining) {
            think = thinkRange.content.trimmingCharacters(in: .whitespacesAndNewlines)
            remaining = thinkRange.cleaned
        }

        let todoMatches = ParsedMessage.extractTags(named: "todo_list", from: remaining)
        remaining = todoMatches.cleaned

        for content in todoMatches.contents {
            if let data = content.data(using: .utf8),
               let payload = try? JSONDecoder().decode(TodoPayload.self, from: data) {
                todos.append(TodoBlock(title: payload.title, status: payload.status, items: payload.items))
            }
        }

        self.thinkContent = think
        self.todoBlocks = todos
        self.markdown = remaining
    }

    private static func extractTag(named name: String, from text: String) -> (content: String, cleaned: String)? {
        let pattern = "<\(name)>([\\s\\S]*?)</\(name)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        guard let range = Range(match.range(at: 1), in: text) else { return nil }
        let content = String(text[range])
        let cleaned = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        return (content, cleaned)
    }

    private static func extractTags(named name: String, from text: String) -> (contents: [String], cleaned: String) {
        let pattern = "<\(name)>([\\s\\S]*?)</\(name)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return ([], text)
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let contents: [String] = matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
        let cleaned = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        return (contents, cleaned)
    }

    private struct TodoPayload: Decodable {
        let title: String
        let status: String?
        let items: [String]
    }
}

private struct ThinkSectionView: View {
    let content: String
    let isStreaming: Bool
    let storageId: String

    @SceneStorage private var isExpanded: Bool

    init(content: String, isStreaming: Bool, storageId: String) {
        self.content = content
        self.isStreaming = isStreaming
        self.storageId = storageId
        _isExpanded = SceneStorage(wrappedValue: false, "thinkExpanded_\(storageId)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("THINK")
                        .font(EnsuTypography.mini)
                        .tracking(0.5)
                        .foregroundStyle(EnsuColor.textMuted)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(EnsuColor.textMuted)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(content)
                    .font(EnsuFont.code(size: 12.5, weight: .regular))
                    .foregroundStyle(EnsuColor.textPrimary)
                    .lineSpacing(EnsuLineHeight.spacing(fontSize: 12.5, lineHeight: 1.45))
                    .textSelection(.enabled)
            } else if isStreaming {
                Text("…" + content)
                    .font(EnsuFont.code(size: 12.5, weight: .regular))
                    .foregroundStyle(EnsuColor.textMuted)
                    .lineLimit(4)
            }
        }
        .padding(EnsuSpacing.cardPadding)
        .background(EnsuColor.fillFaint)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
        .onChange(of: isStreaming) { newValue in
            if !newValue {
                isExpanded = false
            }
        }
    }
}

private struct TodoListCardView: View {
    let title: String
    let status: String?
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
            HStack {
                Text(title)
                    .font(EnsuFont.message(size: 14, weight: .semibold))
                    .foregroundStyle(EnsuColor.textPrimary)
                Spacer()
                Text("\(items.count)")
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
            }

            if let status {
                Text(status)
                    .font(EnsuFont.message(size: 12.5, weight: .regular))
                    .foregroundStyle(EnsuColor.textMuted)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: EnsuSpacing.sm) {
                        Circle()
                            .fill(EnsuColor.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(item)
                            .font(EnsuFont.message(size: 14, weight: .regular))
                            .foregroundStyle(EnsuColor.textPrimary)
                            .lineSpacing(EnsuLineHeight.spacing(fontSize: 14, lineHeight: 1.5))
                    }
                }
            }
        }
        .padding(EnsuSpacing.cardPadding)
        .background(EnsuColor.fillFaint)
        .overlay(
            RoundedRectangle(cornerRadius: EnsuCornerRadius.card)
                .stroke(EnsuColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
    }
}

private struct MarkdownView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.md) {
            ForEach(MarkdownParser.parse(markdown)) { block in
                switch block {
                case .heading(let level, let text):
                    markdownText(text)
                        .font(headingFont(for: level))
                        .foregroundStyle(EnsuColor.textPrimary)
                case .paragraph(let text):
                    markdownText(text)
                        .font(EnsuTypography.message)
                        .foregroundStyle(EnsuColor.textPrimary)
                        .lineSpacing(EnsuLineHeight.spacing(fontSize: 15, lineHeight: 1.7))
                case .blockquote(let text):
                    BlockQuoteView(text: text)
                case .code(let code):
                    CodeBlockView(code: code)
                case .list(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(items, id: \.self) { item in
                            HStack(alignment: .top, spacing: EnsuSpacing.sm) {
                                Text("•")
                                    .font(EnsuTypography.message)
                                    .foregroundStyle(EnsuColor.textPrimary)
                                markdownText(item)
                                    .font(EnsuTypography.message)
                                    .foregroundStyle(EnsuColor.textPrimary)
                            }
                        }
                    }
                case .divider:
                    Divider()
                        .background(EnsuColor.border)
                }
            }
        }
        .textSelection(.enabled)
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:
            return EnsuFont.message(size: 22, weight: .semibold)
        case 2:
            return EnsuFont.message(size: 20, weight: .semibold)
        default:
            return EnsuFont.message(size: 18, weight: .semibold)
        }
    }
}

private func markdownText(_ text: String) -> Text {
    if let attributed = try? AttributedString(markdown: text) {
        return Text(attributed)
    }
    return Text(text)
}

private enum MarkdownBlock: Identifiable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case blockquote(text: String)
    case code(text: String)
    case list(items: [String])
    case divider

    var id: UUID { UUID() }
}

private enum MarkdownParser {
    static func parse(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let segments = text.components(separatedBy: "```")

        for (index, segment) in segments.enumerated() {
            if index % 2 == 1 {
                let code = segment.trimmingCharacters(in: .whitespacesAndNewlines)
                if !code.isEmpty {
                    blocks.append(.code(text: code))
                }
            } else {
                blocks.append(contentsOf: parseTextBlocks(segment))
            }
        }

        return blocks
    }

    private static func parseTextBlocks(_ text: String) -> [MarkdownBlock] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var listItems: [String] = []

        func flushParagraph() {
            if !paragraph.isEmpty {
                blocks.append(.paragraph(text: paragraph.joined(separator: "\n")))
                paragraph.removeAll()
            }
        }

        func flushList() {
            if !listItems.isEmpty {
                blocks.append(.list(items: listItems))
                listItems.removeAll()
            }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                flushList()
                continue
            }

            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                flushList()
                blocks.append(.divider)
                continue
            }

            if trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ") {
                flushParagraph()
                flushList()
                let level = trimmed.prefix(3).filter { $0 == "#" }.count
                let headingText = trimmed.drop(while: { $0 == "#" || $0 == " " })
                blocks.append(.heading(level: max(1, min(level, 3)), text: String(headingText)))
                continue
            }

            if trimmed.hasPrefix(">") {
                flushParagraph()
                flushList()
                let quote = trimmed.drop(while: { $0 == ">" || $0 == " " })
                blocks.append(.blockquote(text: String(quote)))
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                let item = trimmed.dropFirst(2)
                listItems.append(String(item))
                continue
            }

            if let range = trimmed.range(of: ". "),
               let leading = Int(trimmed[..<range.lowerBound]) {
                flushParagraph()
                listItems.append(String(trimmed[range.upperBound...]))
                _ = leading
                continue
            }

            paragraph.append(line)
        }

        flushParagraph()
        flushList()
        return blocks
    }
}

private struct CodeBlockView: View {
    let code: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(EnsuTypography.code)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .lineSpacing(EnsuLineHeight.spacing(fontSize: 13, lineHeight: 1.45))
                    .padding(EnsuSpacing.cardPadding)
                    .textSelection(.enabled)
            }

            Button {
                hapticTap()
                copyToPasteboard(code)
            } label: {
                Image("Copy01Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .padding(6)
                    .background(EnsuColor.fillFaint.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .background(EnsuColor.fillFaint)
        .overlay(
            RoundedRectangle(cornerRadius: EnsuCornerRadius.codeBlock)
                .stroke(EnsuColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.codeBlock, style: .continuous))
    }
}

private struct BlockQuoteView: View {
    let text: String

    var body: some View {
        markdownText(text)
            .font(EnsuTypography.message)
            .foregroundStyle(EnsuColor.textPrimary)
            .padding(EnsuSpacing.cardPadding)
            .background(EnsuColor.fillFaint)
            .overlay(
                Rectangle()
                    .fill(EnsuColor.border)
                    .frame(width: 3),
                alignment: .leading
            )
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
    }
}
#else
import SwiftUI

struct MessageListView: View {
    var body: some View {
        Text("Messages unavailable")
    }
}
#endif

