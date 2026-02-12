#if canImport(EnteCore)
import SwiftUI

struct MessageListView: View {
    let messages: [ChatMessage]
    let streamingResponse: String
    let streamingParentId: UUID?
    let isGenerating: Bool
    let sessionId: UUID?
    let keyboardHeight: CGFloat
    let inputBarHeight: CGFloat
    let emptyStateTitle: String
    let emptyStateSubtitle: String?
    let onEdit: (ChatMessage) -> Void
    let onCopy: (ChatMessage) -> Void
    let onRetry: (ChatMessage) -> Void
    let onBranchChange: (ChatMessage, Int) -> Void
    let onDismissKeyboard: () -> Void

    @State private var isAtBottom = true
    @State private var autoScrollEnabled = true
    @State private var previewItem: AttachmentPreviewItem?
    @State private var wasAtBottomBeforeKeyboard = false
    @State private var isUserDragging = false
    @State private var lastContentHeight: CGFloat = 0
    @State private var lastScrollChange = ScrollChange()
    @State private var didInitialScroll = false
    @State private var suppressAutoScrollAfterGeneration = false
    @State private var showStreamingBubble = false
    @State private var streamingWasGenerating = false
    @State private var streamingAnchorParentId: UUID?
    @State private var streamingAnchorIndex: Int?
    @State private var streamingHideWorkItem: DispatchWorkItem?

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    messageListContent(containerHeight: proxy.size.height)
                }
                .id(sessionId)
                .coordinateSpace(name: "scroll")
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in
                            isUserDragging = true
                            autoScrollEnabled = false
                            onDismissKeyboard()
                        }
                        .onEnded { _ in
                            isUserDragging = false
                            if isAtBottom {
                                autoScrollEnabled = true
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            onDismissKeyboard()
                        }
                )
                .onPreferenceChange(BottomOffsetKey.self) { value in
                    let threshold: CGFloat = EnsuSpacing.xxxl
                    let distanceToBottom = value - proxy.size.height
                    isAtBottom = distanceToBottom <= threshold
                }
                .onPreferenceChange(ContentHeightKey.self) { newHeight in
                    let delta = newHeight - lastContentHeight
                    lastContentHeight = newHeight
                    let lastMessageIsUser = messages.last?.role == .user
                    if delta > 1,
                       autoScrollEnabled,
                       !isUserDragging,
                       !isGenerating,
                       !suppressAutoScrollAfterGeneration,
                       lastMessageIsUser {
                        scrollToBottom(scrollProxy, force: true, animated: true)
                    }
                }
                .onChange(of: currentScrollChange) { newValue in
                    handleScrollChange(newValue, scrollProxy: scrollProxy)
                }
                .onAppear {
                    lastScrollChange = currentScrollChange
                    didInitialScroll = false
                    showStreamingBubble = isGenerating
                    streamingWasGenerating = isGenerating
                    streamingAnchorParentId = streamingParentId
                    streamingAnchorIndex = streamingParentId.flatMap { parentId in
                        messages.firstIndex(where: { $0.id == parentId })
                    }
                    scheduleInitialScroll(scrollProxy)
                }
                .onChange(of: isGenerating) { generating in
                    if generating {
                        streamingHideWorkItem?.cancel()
                        streamingHideWorkItem = nil
                        showStreamingBubble = true
                        streamingAnchorParentId = streamingParentId
                        streamingAnchorIndex = streamingParentId.flatMap { parentId in
                            messages.firstIndex(where: { $0.id == parentId })
                        }
                        suppressAutoScrollAfterGeneration = false
                    } else {
                        suppressAutoScrollAfterGeneration = true
                        if streamingWasGenerating {
                            let workItem = DispatchWorkItem {
                                withAnimation(.easeInOut(duration: 0.30)) {
                                    showStreamingBubble = false
                                }
                                suppressAutoScrollAfterGeneration = false
                                streamingHideWorkItem = nil
                            }
                            streamingHideWorkItem?.cancel()
                            streamingHideWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.52, execute: workItem)
                        }
                    }
                    streamingWasGenerating = generating
                }
                .onChange(of: streamingParentId) { parentId in
                    if isGenerating {
                        streamingAnchorParentId = parentId
                        streamingAnchorIndex = parentId.flatMap { anchorId in
                            messages.firstIndex(where: { $0.id == anchorId })
                        }
                    }
                }
                .onChange(of: messages.count) { _ in
                    if isGenerating, let anchorId = streamingAnchorParentId {
                        streamingAnchorIndex = messages.firstIndex(where: { $0.id == anchorId })
                    }
                }
                .onChange(of: sessionId) { _ in
                    streamingHideWorkItem?.cancel()
                    streamingHideWorkItem = nil
                    showStreamingBubble = isGenerating
                    streamingWasGenerating = isGenerating
                    streamingAnchorParentId = streamingParentId
                    streamingAnchorIndex = streamingParentId.flatMap { parentId in
                        messages.firstIndex(where: { $0.id == parentId })
                    }
                }
            }
        }
        .sheet(item: $previewItem) { item in
            QuickLookPreview(url: item.url)
        }
    }

    private var currentScrollChange: ScrollChange {
        ScrollChange(
            messagesCount: messages.count,
            sessionId: sessionId,
            streamingLength: streamingResponse.count,
            keyboardHeight: keyboardHeight,
            inputBarHeight: inputBarHeight,
            isGenerating: isGenerating,
            isAtBottom: isAtBottom
        )
    }

    private func handleScrollChange(_ newValue: ScrollChange, scrollProxy: ScrollViewProxy) {
        let previous = lastScrollChange
        lastScrollChange = newValue
        let didGenerationJustFinish = previous.isGenerating && !newValue.isGenerating

        if newValue.messagesCount != previous.messagesCount {
            if !didInitialScroll {
                scheduleInitialScroll(scrollProxy)
            } else if messages.last?.role == .user {
                autoScrollEnabled = true
                scrollToBottom(scrollProxy, force: true, animated: true)
            }
        }

        if newValue.sessionId != previous.sessionId {
            autoScrollEnabled = true
            didInitialScroll = false
            scheduleInitialScroll(scrollProxy)
        }

        if newValue.keyboardHeight != previous.keyboardHeight {
            if newValue.keyboardHeight > 0 {
                wasAtBottomBeforeKeyboard = isAtBottom
            }
            if wasAtBottomBeforeKeyboard && !didGenerationJustFinish && !suppressAutoScrollAfterGeneration {
                autoScrollEnabled = true
                scrollToBottom(scrollProxy, force: true, animated: false)
            }
            if newValue.keyboardHeight == 0 {
                wasAtBottomBeforeKeyboard = false
            }
        }

        if newValue.inputBarHeight != previous.inputBarHeight {
            if autoScrollEnabled &&
                !isUserDragging &&
                !isGenerating &&
                !didGenerationJustFinish &&
                !suppressAutoScrollAfterGeneration {
                scrollToBottom(scrollProxy, force: true, animated: false)
            }
        }

        if newValue.isAtBottom != previous.isAtBottom {
            if newValue.isAtBottom && !isUserDragging {
                autoScrollEnabled = true
            }
        }
    }

    @ViewBuilder
    private func messageListContent(containerHeight: CGFloat) -> some View {
        let emptyStateMinHeight = max(0, containerHeight - contentBottomPadding - (EnsuSpacing.lg * 2))

        VStack(alignment: .leading, spacing: 0) {
            LazyVStack(alignment: .leading, spacing: EnsuSpacing.lg) {
                if messages.isEmpty && !isGenerating {
                    VStack {
                        Spacer(minLength: 0)
                        VStack(spacing: EnsuSpacing.sm) {
                            Text(emptyStateTitle)
                                .font(EnsuTypography.h2)
                                .foregroundStyle(EnsuColor.textPrimary)
                            if let emptyStateSubtitle {
                                Text(emptyStateSubtitle)
                                    .font(EnsuTypography.body)
                                    .foregroundStyle(EnsuColor.textMuted)
                            }
                        }
                        .multilineTextAlignment(.center)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: emptyStateMinHeight)
                }

                let shouldShowStreaming = isGenerating || showStreamingBubble
                let activeStreamingParentId = isGenerating ? streamingParentId : streamingAnchorParentId
                let activeStreamingIndex = isGenerating
                    ? streamingParentId.flatMap { parentId in messages.firstIndex(where: { $0.id == parentId }) }
                    : streamingAnchorIndex

                ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                    if message.role == .user {
                        UserMessageBubbleView(
                            message: message,
                            onEdit: { onEdit(message) },
                            onCopy: { onCopy(message) },
                            onBranchChange: { delta in onBranchChange(message, delta) },
                            onOpenAttachment: openAttachment
                        )
                        .id(message.id)
                        .transition(messageTransition)
                    } else {
                        AssistantMessageBubbleView(
                            message: message,
                            onCopy: { onCopy(message) },
                            onRetry: { onRetry(message) },
                            onBranchChange: { delta in onBranchChange(message, delta) },
                            onOpenAttachment: openAttachment
                        )
                        .id(message.id)
                        .transition(messageTransition)
                    }

                    let isAnchoredById = activeStreamingParentId == message.id
                    let isAnchoredByIndex = activeStreamingIndex == index
                    if shouldShowStreaming && (isAnchoredById || isAnchoredByIndex) {
                        StreamingBubbleView(
                            text: streamingResponse,
                            isGenerating: isGenerating,
                            isOutroPhase: !isGenerating && showStreamingBubble
                        )
                        .id("streaming-\(message.id.uuidString)")
                        .transition(streamingTransition)
                    }
                }

                if shouldShowStreaming && activeStreamingParentId == nil && activeStreamingIndex == nil {
                    StreamingBubbleView(
                        text: streamingResponse,
                        isGenerating: isGenerating,
                        isOutroPhase: !isGenerating && showStreamingBubble
                    )
                    .id("streaming-root")
                    .transition(streamingTransition)
                }
            }
            .padding(.horizontal, EnsuSpacing.pageHorizontal)
            .padding(.top, EnsuSpacing.lg)
            .padding(.bottom, EnsuSpacing.lg)
            .animation(isGenerating ? .spring(response: 0.35, dampingFraction: 0.86) : nil, value: messages.count)
            .animation(.easeInOut(duration: 0.30), value: showStreamingBubble)

            Color.clear
                .frame(height: contentBottomPadding)
                .id("bottom")
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: BottomOffsetKey.self, value: geo.frame(in: .named("scroll")).maxY)
                    }
                )
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ContentHeightKey.self, value: geo.size.height)
            }
        )
    }

    private var messageTransition: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    private var streamingTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading)),
            removal: .opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading))
        )
    }

    private var contentBottomPadding: CGFloat {
        let fallbackPadding = EnsuSpacing.xxxl + EnsuSpacing.xxl + 60
        let measuredPadding = inputBarHeight > 0 ? inputBarHeight + EnsuSpacing.md : fallbackPadding
        let basePadding = max(fallbackPadding, measuredPadding)
        return basePadding
    }

    private func scheduleInitialScroll(_ proxy: ScrollViewProxy) {
        guard !didInitialScroll else { return }
        DispatchQueue.main.async {
            scrollToBottom(proxy, force: true, animated: false)
            didInitialScroll = true
        }
    }

    private func scrollToBottom(_ : ScrollViewProxy, force _: Bool = false, animated _: Bool = true) {
        // Intentionally no-op: auto-scroll is disabled for Swift chat.
    }

    private func openAttachment(_ attachment: ChatAttachment) {
        guard let url = attachment.url else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = sanitizedAttachmentName(attachment)
        let previewUrl = tempDir.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: previewUrl.path) {
                try FileManager.default.removeItem(at: previewUrl)
            }
            try FileManager.default.copyItem(at: url, to: previewUrl)
            previewItem = AttachmentPreviewItem(url: previewUrl)
        } catch {
            previewItem = AttachmentPreviewItem(url: url)
        }
    }

    private func sanitizedAttachmentName(_ attachment: ChatAttachment) -> String {
        let rawName = attachment.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = rawName.isEmpty ? attachment.id.uuidString : rawName
        let invalidCharacters = CharacterSet(charactersIn: "/\\:")
        let sanitized = baseName.components(separatedBy: invalidCharacters).joined(separator: "-")
        return sanitized.isEmpty ? attachment.id.uuidString : sanitized
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

