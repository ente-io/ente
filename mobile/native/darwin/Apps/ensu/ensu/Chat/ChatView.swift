#if canImport(EnteCore)
import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isShowingAuth: Bool

    @EnvironmentObject private var appState: EnsuAppState
    @ObservedObject private var modelSettings = ModelSettingsStore.shared

    @State private var isDrawerOpen = false
    @State private var showSettings = false
    @State private var toastMessage: ToastMessage?
    @StateObject private var keyboard = KeyboardObserver()
    @State private var deleteSession: ChatSession?
    @State private var developerTapCount = 0
    @State private var lastDeveloperTapAt: Date?
    @State private var isOpeningDeveloperSettings = false
    @State private var showDeveloperAlert = false
    @State private var showDeveloperSettings = false
    @State private var showAttachmentDownloads = false
    @State private var didAutoFocusInput = false
    @FocusState private var isInputFocused: Bool
    @State private var inputBarHeight: CGFloat = 0
    @State private var wasDrawerOpen = false
    @State private var didDismissKeyboard = false

    private var editingMessage: ChatMessage? {
        guard let editingId = viewModel.editingMessageId else { return nil }
        return viewModel.messages.first { $0.id == editingId }
    }

    private let drawerWidth: CGFloat = 320
    private let drawerAutoThreshold: CGFloat = 900
    private let drawerHiddenOffset: CGFloat = -340

    var body: some View {
        GeometryReader { proxy in
            let isWideLayout = proxy.size.width >= drawerAutoThreshold

            ZStack(alignment: .topLeading) {
                EnsuColor.backgroundBase
                    .ignoresSafeArea()

                if isWideLayout {
                    HStack(spacing: 0) {
                        drawerView(isPinned: true)

                        Divider()
                            .background(EnsuColor.border)

                        mainContent(showsMenuButton: false)
                    }
                } else {
                    mainContent(showsMenuButton: true)
                        .overlay(alignment: .leading) {
                            #if os(iOS)
                            Color.clear
                                .frame(width: 24)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onEnded { value in
                                            guard !isDrawerOpen else { return }
                                            guard value.startLocation.x <= 24 else { return }
                                            let horizontal = value.translation.width
                                            let vertical = value.translation.height
                                            guard abs(horizontal) > abs(vertical), horizontal > 40 else { return }
                                            isDrawerOpen = true
                                        }
                                )
                            #endif
                        }

                    if isDrawerOpen {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                            .onTapGesture { isDrawerOpen = false }
                            #if os(iOS)
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onEnded { value in
                                        let horizontal = value.translation.width
                                        let vertical = value.translation.height
                                        guard abs(horizontal) > abs(vertical), horizontal < -40 else { return }
                                        isDrawerOpen = false
                                    }
                            )
                            #endif
                    }

                    drawerView(isPinned: false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: isWideLayout) { newValue in
                if newValue {
                    isDrawerOpen = false
                }
            }
            .onChange(of: isDrawerOpen) { isOpen in
                if isOpen {
                    isInputFocused = false
                    wasDrawerOpen = true
                } else if wasDrawerOpen {
                    let shouldRestoreFocus = viewModel.isModelDownloaded
                        && !viewModel.isDownloading
                        && !viewModel.isGenerating
                        && !didDismissKeyboard
                        && !showSettings
                        && !showDeveloperSettings
                    if shouldRestoreFocus {
                        requestInputFocus()
                    }
                    wasDrawerOpen = false
                }
            }
            .onChange(of: viewModel.syncErrorMessage) { message in
                guard let message else { return }
                showToast(message, duration: 2)
                viewModel.syncErrorMessage = nil
            }
            .onChange(of: viewModel.syncSuccessMessage) { message in
                guard let message else { return }
                showToast(message, duration: 2)
                viewModel.syncSuccessMessage = nil
            }
            .onChange(of: viewModel.generationErrorMessage) { message in
                guard let message else { return }
                showToast(message, duration: 2)
                viewModel.generationErrorMessage = nil
            }
            .onChange(of: modelSettings.useCustomModel) { _ in
                viewModel.refreshModelDownloadInfo()
            }
            .onChange(of: modelSettings.modelUrl) { _ in
                viewModel.refreshModelDownloadInfo()
            }
            .onChange(of: modelSettings.mmprojUrl) { _ in
                viewModel.refreshModelDownloadInfo()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                isLoggedIn: appState.isLoggedIn,
                email: CredentialStore.shared.email,
                onSignOut: {
                    appState.logout()
                    showSettings = false
                    isDrawerOpen = false
                },
                onSignIn: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        isShowingAuth = true
                    }
                }
            )
        }
        .onChange(of: showSettings) { isPresented in
            if isPresented {
                didDismissKeyboard = true
                isInputFocused = false
            }
        }
        .sheet(isPresented: $showAttachmentDownloads) {
            AttachmentDownloadsSheet(
                downloads: viewModel.attachmentDownloads,
                sessionTitle: { viewModel.sessionTitle(for: $0) },
                onCancel: { viewModel.cancelAttachmentDownload($0) },
                onDismiss: { showAttachmentDownloads = false }
            )
        }
        .platformFullScreenCover(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView { message in
                showToast(message, duration: 2)
            }
        }
        .alert("Developer settings", isPresented: $showDeveloperAlert) {
            Button("Yes") {
                showDeveloperSettings = true
                isOpeningDeveloperSettings = false
            }
            Button("Cancel", role: .cancel) {
                isOpeningDeveloperSettings = false
            }
        } message: {
            Text("Are you sure that you want to modify Developer settings?")
        }
        .alert(item: $deleteSession) { session in
            Alert(
                title: Text("Delete Chat"),
                message: Text("Are you sure you want to delete this chat?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteSession(session)
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage.text)
                    .padding(.bottom, EnsuSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func mainContent(showsMenuButton: Bool) -> some View {
        VStack(spacing: 0) {
            ChatAppBar(
                sessionTitle: viewModel.currentSessionId.map { viewModel.sessionTitle(for: $0) } ?? "New chat",
                showBrand: viewModel.messages.isEmpty,
                showSignIn: !appState.isLoggedIn,
                showsMenuButton: showsMenuButton,
                attachmentDownloadSummary: viewModel.attachmentDownloadSummary,
                modelDownloadState: viewModel.downloadToast,
                onMenu: { isDrawerOpen.toggle() },
                onSignIn: { isShowingAuth = true },
                onAttachmentDownloads: {
                    showAttachmentDownloads = true
                }
            )

            Divider()
                .background(EnsuColor.border)

            ZStack(alignment: .top) {
                let shouldShowDownloadOnboarding = !viewModel.isModelDownloaded

                MessageListView(
                    messages: viewModel.messages,
                    streamingResponse: viewModel.displayedStreamingResponse,
                    streamingParentId: viewModel.displayedStreamingParentId,
                    isGenerating: viewModel.isGenerating,
                    sessionId: viewModel.currentSessionId,
                    keyboardHeight: keyboard.height,
                    inputBarHeight: viewModel.isModelDownloaded ? inputBarHeight : 0,
                    emptyStateTitle: "Welcome",
                    emptyStateSubtitle: "Start typing to begin a conversation",
                    onEdit: { message in
                        viewModel.beginEditing(message: message)
                    },
                    onCopy: { message in
                        copyToPasteboard(message.text)
                        showToast("Copied to clipboard", duration: 1)
                    },
                    onRetry: { message in
                        viewModel.retryAssistantResponse(message)
                    },
                    onBranchChange: { message, delta in
                        viewModel.changeBranch(for: message, delta: delta)
                    },
                    onDismissKeyboard: {
                        didDismissKeyboard = true
                        isInputFocused = false
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .overlay(alignment: .bottom) {
                    if viewModel.isModelDownloaded {
                        let shouldAutoFocus = viewModel.isModelDownloaded
                            && !viewModel.isDownloading
                            && !viewModel.isGenerating
                            && !didAutoFocusInput
                            && !isDrawerOpen
                            && !didDismissKeyboard
                            && !showSettings
                            && !showDeveloperSettings

                        MessageInputView(
                            text: $viewModel.draftText,
                            attachments: $viewModel.draftAttachments,
                            isGenerating: viewModel.isGenerating,
                            isDownloading: viewModel.isDownloading,
                            editingMessage: editingMessage,
                            isProcessingAttachments: viewModel.isProcessingAttachments,
                            isAttachmentDownloadBlocked: viewModel.isAttachmentDownloadBlocked,
                            onSend: {
                                viewModel.sendDraft()
                            },
                            onStop: {
                                viewModel.stopGenerating()
                            },
                            onCancelEdit: {
                                viewModel.cancelEditing()
                            },
                            onAddImage: { data, name in
                                viewModel.addImageAttachment(data: data, fileName: name)
                            },
                            onAddDocument: { url in
                                viewModel.addDocumentAttachment(url: url)
                            },
                            onRemoveAttachment: { attachment in
                                viewModel.removeAttachment(attachment)
                            },
                            onUserFocus: {
                                didDismissKeyboard = false
                            },
                            onDismissKeyboard: {
                                didDismissKeyboard = true
                            },
                            isFocused: $isInputFocused
                        )
                        .onPreferenceChange(InputBarHeightKey.self) { newValue in
                            inputBarHeight = newValue
                        }
                        .onAppear {
                            if shouldAutoFocus {
                                requestInputFocus()
                                didAutoFocusInput = true
                                didDismissKeyboard = false
                            }
                        }
                        .onChange(of: shouldAutoFocus) { newValue in
                            if newValue {
                                requestInputFocus()
                                didAutoFocusInput = true
                                didDismissKeyboard = false
                            }
                        }
                    }
                }
                .onAppear {
                    viewModel.autoStartModelDownloadIfNeeded()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    viewModel.autoStartModelDownloadIfNeeded()
                }

                if shouldShowDownloadOnboarding {
                    DownloadOnboardingView(
                        isDownloading: viewModel.isDownloading,
                        downloadPercent: viewModel.downloadToast?.percent,
                        statusText: viewModel.downloadToast?.status,
                        totalBytes: viewModel.modelDownloadSizeBytes,
                        sizeText: viewModel.modelDownloadSizeText,
                        onDownload: {
                            viewModel.startModelDownload(userInitiated: true)
                        }
                    )
                    .background(EnsuColor.backgroundBase)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func drawerView(isPinned: Bool) -> some View {
        let drawer = SessionDrawerView(
            sessions: viewModel.sessions,
            currentSessionId: viewModel.currentSessionId,
            isLoggedIn: appState.isLoggedIn,
            email: CredentialStore.shared.email,
            onNewChat: {
                viewModel.startNewSession()
                isDrawerOpen = false
            },
            onSelectSession: { session in
                viewModel.selectSession(session)
                isDrawerOpen = false
            },
            onDeleteSession: { session in
                deleteSession = session
            },
            onSync: {
                viewModel.syncNow(showErrors: true, showSuccess: true)
            },
            onOpenSettings: {
                isDrawerOpen = false
                showSettings = true
            },
            onDeveloperTap: {
                handleDeveloperTap()
            }
        )
        .frame(width: drawerWidth)

        if isPinned {
            drawer
        } else {
            drawer
                .offset(x: isDrawerOpen ? 0 : drawerHiddenOffset)
                .animation(.easeOut(duration: 0.25), value: isDrawerOpen)
        }
    }

    private func showToast(_ text: String, duration: TimeInterval) {
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = ToastMessage(text: text)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeIn(duration: 0.2)) {
                toastMessage = nil
            }
        }
    }

    private func requestInputFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isInputFocused = true
        }
    }

    private func handleDeveloperTap() {
        // Don't allow switching endpoints for logged-in users.
        guard !appState.isLoggedIn else { return }

        let now = Date()
        if let lastDeveloperTapAt,
           now.timeIntervalSince(lastDeveloperTapAt) > 2 {
            developerTapCount = 0
        }

        lastDeveloperTapAt = now
        developerTapCount += 1

        guard developerTapCount >= 5 else { return }
        developerTapCount = 0
        presentDeveloperPrompt()
    }

    private func presentDeveloperPrompt() {
        guard !isOpeningDeveloperSettings else { return }
        isOpeningDeveloperSettings = true
        showDeveloperAlert = true
    }
}

private struct DownloadOnboardingView: View {
    let isDownloading: Bool
    let downloadPercent: Int?
    let statusText: String?
    let totalBytes: Int64?
    let sizeText: String
    let onDownload: () -> Void

    var body: some View {
        VStack(spacing: EnsuSpacing.md) {
            Text("Download to begin using the Chat")
                .font(EnsuTypography.large)
                .foregroundStyle(EnsuColor.textPrimary)
                .multilineTextAlignment(.center)

            if isDownloading {
                let statusLine: String = {
                    if let statusText, statusText.localizedCaseInsensitiveContains("loading") {
                        return statusText
                    }
                    if let totalBytes, let percent = downloadPercent, percent >= 0 {
                        let clamped = min(max(percent, 0), 100)
                        let downloaded = Int64(Double(totalBytes) * Double(clamped) / 100.0)
                        return "Downloading... \(formatBytes(downloaded)) / \(formatBytes(totalBytes))"
                    }
                    if let statusText, !statusText.isEmpty {
                        return statusText
                    }
                    return "Downloading..."
                }()

                Text(statusLine)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)
                    .multilineTextAlignment(.center)

                progressView
            } else {
                Button("Download") {
                    hapticMedium()
                    onDownload()
                }
                .font(EnsuTypography.body)
                .foregroundStyle(EnsuColor.backgroundBase)
                .frame(maxWidth: 200)
                .padding(.vertical, EnsuSpacing.md)
                .background(EnsuColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.button))

                Text(sizeText)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
    }

    @ViewBuilder
    private var progressView: some View {
        if let percent = downloadPercent, percent >= 0 {
            let clamped = min(max(percent, 0), 100)
            ProgressView(value: Double(clamped), total: 100)
                .progressViewStyle(.linear)
                .tint(EnsuColor.accent)
                .frame(maxWidth: 240)
        } else {
            ProgressView()
                .progressViewStyle(.linear)
                .tint(EnsuColor.accent)
                .frame(maxWidth: 240)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
}

private struct AttachmentDownloadsSheet: View {
    let downloads: [AttachmentDownloadItem]
    let sessionTitle: (UUID) -> String
    let onCancel: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Attachment downloads")
                    .font(EnsuTypography.h3Bold)
                Spacer()
                Button("Close", action: onDismiss)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.accent)
            }
            .padding(.horizontal, EnsuSpacing.pageHorizontal)
            .padding(.vertical, EnsuSpacing.sm)

            Divider()
                .background(EnsuColor.border)

            if downloads.isEmpty {
                Text("No pending downloads")
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)
                    .padding(.top, EnsuSpacing.lg)
                Spacer()
            } else {
                List(downloads) { item in
                    HStack(spacing: EnsuSpacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(EnsuTypography.body)
                                .foregroundStyle(EnsuColor.textPrimary)
                                .lineLimit(1)
                            Text("\(sessionTitle(item.sessionId)) • \(item.formattedSize)")
                                .font(EnsuTypography.mini)
                                .foregroundStyle(EnsuColor.textMuted)
                            if item.status == .failed, let errorMessage = item.errorMessage, !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(EnsuTypography.mini)
                                    .foregroundStyle(EnsuColor.error)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        Text(statusText(for: item.status))
                            .font(EnsuTypography.mini)
                            .foregroundStyle(EnsuColor.textMuted)

                        if item.status == .queued || item.status == .downloading {
                            Button(action: {
                                hapticWarning()
                                onCancel(item.id)
                            }) {
                                Image("Cancel01Icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(EnsuColor.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .frame(minHeight: 320)
        .background(EnsuColor.backgroundBase)
    }

    private func statusText(for status: AttachmentDownloadItem.Status) -> String {
        switch status {
        case .queued:
            return "Queued"
        case .downloading:
            return "Downloading"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .canceled:
            return "Canceled"
        }
    }
}

private struct ChatAppBar: View {
    let sessionTitle: String
    let showBrand: Bool
    let showSignIn: Bool
    let showsMenuButton: Bool
    let attachmentDownloadSummary: (completed: Int, total: Int)?
    let modelDownloadState: DownloadToastState?
    let onMenu: () -> Void
    let onSignIn: () -> Void
    let onAttachmentDownloads: () -> Void

    private let centerInset: CGFloat = 72

    private var modelProgressState: DownloadToastState? {
        guard let modelDownloadState else { return nil }
        switch modelDownloadState.phase {
        case .loading, .downloading:
            return modelDownloadState
        default:
            return nil
        }
    }

    var body: some View {
        ZStack {
            HStack(spacing: EnsuSpacing.md) {
                if showsMenuButton {
                    Button(action: {
                        hapticTap()
                        onMenu()
                    }) {
                        Image("Menu01Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 40, height: 40)
                }

                Spacer()

                HStack(spacing: EnsuSpacing.md) {
                    if showSignIn {
                        if let progress = modelProgressState {
                            ModelProgressIndicator(state: progress)
                        }
                        Button(action: {
                            hapticTap()
                            onSignIn()
                        }) {
                            Text("Sign In")
                                .font(EnsuTypography.small)
                                .foregroundStyle(EnsuColor.accent)
                        }
                        .buttonStyle(.plain)
                    } else {
                        if let summary = attachmentDownloadSummary {
                            Button(action: {
                                hapticTap()
                                onAttachmentDownloads()
                            }) {
                                HStack(spacing: 6) {
                                    Image("Upload01Icon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundStyle(EnsuColor.textPrimary)
                                    Text("\(summary.completed)/\(summary.total)")
                                        .font(EnsuTypography.mini)
                                        .foregroundStyle(EnsuColor.textMuted)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(EnsuColor.fillFaint)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        if let progress = modelProgressState {
                            ModelProgressIndicator(state: progress)
                        }
                    }
                }
            }

            if showBrand {
                EnsuLogo(height: 20)
                    .padding(.horizontal, centerInset)
            } else {
                Text(sessionTitle)
                    .font(EnsuTypography.large)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, centerInset)
            }
        }
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
        .padding(.vertical, EnsuSpacing.sm)
        .background(EnsuColor.backgroundBase)
    }
}

private struct ModelProgressIndicator: View {
    let state: DownloadToastState

    var body: some View {
        let clamped = min(max(state.percent, 0), 100)
        if state.phase == .downloading {
            ProgressView(value: Double(clamped), total: 100)
                .progressViewStyle(.circular)
                .tint(EnsuColor.accent)
                .frame(width: 16, height: 16)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(EnsuColor.accent)
                .frame(width: 16, height: 16)
        }
    }
}
#else
import SwiftUI

struct ChatView: View {
    var body: some View {
        Text("Chat unavailable")
    }
}
#endif
