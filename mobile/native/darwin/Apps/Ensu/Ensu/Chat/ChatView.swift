#if canImport(EnteCore)
import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isShowingAuth: Bool

    @EnvironmentObject private var appState: EnsuAppState
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var modelSettings = ModelSettingsStore.shared

    @StateObject private var viewState = ChatViewState()
    @StateObject private var keyboard = KeyboardObserver()
    @FocusState private var isInputFocused: Bool

    private var editingMessage: RenderedChatMessage? {
        guard let editingId = viewModel.editingMessageId else { return nil }
        return viewModel.messages.first { $0.id == editingId }
    }

    private var toastTrigger: ToastTrigger {
        ToastTrigger(
            syncError: viewModel.syncErrorMessage,
            syncSuccess: viewModel.syncSuccessMessage,
            generationError: viewModel.generationErrorMessage
        )
    }

    private var shouldAutoFocusInput: Bool {
        viewModel.isModelDownloaded
            && !viewModel.isDownloading
            && !viewModel.isGenerating
            && !viewState.didAutoFocusInput
            && !viewState.isDrawerOpen
            && !viewState.didDismissKeyboard
            && !viewState.showSettings
    }

    private var overflowDialogPresented: Binding<Bool> {
        Binding(
            get: { viewModel.overflowAlert != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.cancelOverflowDialog()
                }
            }
        )
    }

    private var modelSettingsSignature: String {
        "\(modelSettings.useCustomModel)|\(modelSettings.modelUrl)|\(modelSettings.mmprojUrl)"
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
                                            guard !viewState.isDrawerOpen else { return }
                                            guard value.startLocation.x <= 24 else { return }
                                            let horizontal = value.translation.width
                                            let vertical = value.translation.height
                                            guard abs(horizontal) > abs(vertical), horizontal > 40 else { return }
                                            viewState.isDrawerOpen = true
                                        }
                                )
                            #endif
                        }

                    if viewState.isDrawerOpen {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                            .onTapGesture { viewState.isDrawerOpen = false }
                            #if os(iOS)
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onEnded { value in
                                        let horizontal = value.translation.width
                                        let vertical = value.translation.height
                                        guard abs(horizontal) > abs(vertical), horizontal < -40 else { return }
                                        viewState.isDrawerOpen = false
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
                    viewState.isDrawerOpen = false
                }
            }
            .onChange(of: viewState.isDrawerOpen) { isOpen in
                if isOpen {
                    isInputFocused = false
                    viewState.wasDrawerOpen = true
                } else if viewState.wasDrawerOpen {
                    let shouldRestoreFocus = viewModel.isModelDownloaded
                        && !viewModel.isDownloading
                        && !viewModel.isGenerating
                        && !viewState.didDismissKeyboard
                        && !viewState.showSettings
                    if shouldRestoreFocus {
                        requestInputFocus()
                    }
                    viewState.wasDrawerOpen = false
                }
            }
            .onChange(of: toastTrigger) { trigger in
                handleToastTrigger(trigger)
            }
            .onChange(of: modelSettingsSignature) { _ in
                viewModel.refreshModelDownloadInfo()
            }
            .onChange(of: scenePhase) { newValue in
                if newValue == .active {
                    viewModel.refreshModelDownloadInfo()
                }
            }
        }
        .sheet(isPresented: $viewState.showSettings) {
            SettingsView(
                isLoggedIn: appState.isLoggedIn,
                email: CredentialStore.shared.email,
                showsSignInOption: EnsuFeatureFlags.enableSignIn,
                onSignOut: {
                    appState.logout()
                    viewState.showSettings = false
                    viewState.isDrawerOpen = false
                },
                onSignIn: {
                    guard EnsuFeatureFlags.enableSignIn else { return }
                    viewState.pendingSignInRequest = true
                    viewState.showSettings = false
                }
            )
        }
        .onChange(of: viewState.showSettings) { isPresented in
            if isPresented {
                viewState.didDismissKeyboard = true
                isInputFocused = false
            } else if viewState.pendingSignInRequest {
                viewState.pendingSignInRequest = false
                guard EnsuFeatureFlags.enableSignIn else { return }
                handleSignInRequest()
            }
        }
        .sheet(isPresented: $viewState.showAttachmentDownloads) {
            AttachmentDownloadsSheet(
                downloads: viewModel.attachmentDownloads,
                sessionTitle: { viewModel.sessionTitle(for: $0) },
                onCancel: { viewModel.cancelAttachmentDownload($0) },
                onDismiss: { viewState.showAttachmentDownloads = false }
            )
        }
        .alert(item: $viewState.deleteSession) { session in
            Alert(
                title: Text("Delete Chat"),
                message: Text("Are you sure you want to delete this chat?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteSession(session)
                },
                secondaryButton: .cancel()
            )
        }
        .confirmationDialog("Conversation too long", isPresented: overflowDialogPresented, titleVisibility: .visible) {
            Button("Continue") {
                viewModel.confirmOverflowTrim()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelOverflowDialog()
            }
        } message: {
            Text("This conversation is too long for the model to process. Some older messages will be dropped to make room.")
        }
        .overlay {
            if viewState.showSignInComingSoon {
                SignInComingSoonDialog(
                    title: "Coming Soon",
                    message: "Sign in and cloud backup will be available in a future update."
                ) {
                    viewState.showSignInComingSoon = false
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = viewState.toastMessage {
                ToastView(message: toastMessage.text)
                    .padding(.bottom, EnsuSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        #if os(iOS)
        .ignoresSafeArea(.keyboard)
        #endif
    }

    @ViewBuilder
    private func mainContent(showsMenuButton: Bool) -> some View {
        VStack(spacing: 0) {
            ChatAppBar(
                sessionTitle: viewModel.currentSessionId.map { viewModel.sessionTitle(for: $0) } ?? "New chat",
                showBrand: viewModel.messages.isEmpty,
                showSignIn: EnsuFeatureFlags.enableSignIn && !appState.isLoggedIn,
                showsMenuButton: showsMenuButton,
                attachmentDownloadSummary: viewModel.attachmentDownloadSummary,
                modelDownloadState: viewModel.downloadToast,
                onMenu: { viewState.isDrawerOpen.toggle() },
                onSignIn: {
                    guard EnsuFeatureFlags.enableSignIn else { return }
                    handleSignInRequest()
                },
                onNewChat: {
                    viewModel.startNewSession()
                    viewState.isDrawerOpen = false
                },
                onAttachmentDownloads: {
                    viewState.showAttachmentDownloads = true
                }
            )

            Divider()
                .background(EnsuColor.border)

            let sessionTransition = AnyTransition.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
            .animation(.easeInOut(duration: 0.32))

            ZStack(alignment: .bottom) {
                let shouldShowDownloadOnboarding = !viewModel.isModelDownloaded

                MessageListView(
                    messages: viewModel.messages,
                    streamingResponse: viewModel.displayedStreamingResponse,
                    streamingParentId: viewModel.displayedStreamingParentId,
                    isGenerating: viewModel.isGenerating,
                    sessionId: viewModel.currentSessionId,
                    keyboardHeight: keyboard.height,
                    inputBarHeight: viewModel.isModelDownloaded ? viewState.inputBarHeight : 0,
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
                        viewState.didDismissKeyboard = true
                        isInputFocused = false
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .id(viewState.sessionTransitionId)
                .transition(sessionTransition)
                .onAppear {
                    viewModel.autoStartModelDownloadIfNeeded()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    viewModel.autoStartModelDownloadIfNeeded()
                }
                .zIndex(0)

                if viewModel.isModelDownloaded {
                    let shouldAutoFocus = shouldAutoFocusInput

                    MessageInputView(
                        text: $viewModel.draftText,
                        attachments: $viewModel.draftAttachments,
                        isGenerating: viewModel.isGenerating,
                        isDownloading: viewModel.isDownloading,
                        editingMessage: editingMessage,
                        isProcessingAttachments: viewModel.isProcessingAttachments,
                        isAttachmentDownloadBlocked: viewModel.isAttachmentDownloadBlocked,
                        onSend: {
                            viewState.didDismissKeyboard = true
                            isInputFocused = false
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
                            viewState.didDismissKeyboard = false
                        },
                        onDismissKeyboard: {
                            viewState.didDismissKeyboard = true
                        },
                        isFocused: $isInputFocused
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .onPreferenceChange(InputBarHeightKey.self) { newValue in
                        viewState.inputBarHeight = newValue
                    }
                    .onAppear {
                        if shouldAutoFocus {
                            requestInputFocus()
                            viewState.didAutoFocusInput = true
                            viewState.didDismissKeyboard = false
                        }
                    }
                    .onChange(of: shouldAutoFocus) { newValue in
                        if newValue {
                            requestInputFocus()
                            viewState.didAutoFocusInput = true
                            viewState.didDismissKeyboard = false
                        }
                    }
                    .padding(.bottom, keyboard.isVisible ? keyboard.height : 0)
                    .zIndex(1)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(EnsuColor.backgroundBase)
                    .zIndex(2)
                }

            }
            .animation(.easeInOut(duration: 0.32), value: viewState.sessionTransitionId)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: viewModel.currentSessionId) { _ in
            withAnimation(.easeInOut(duration: 0.32)) {
                viewState.sessionTransitionId = UUID()
            }
        }
    }

    @ViewBuilder
    private func drawerView(isPinned: Bool) -> some View {
        let drawer = SessionDrawerView(
            sessions: viewModel.sessions,
            currentSessionId: viewModel.currentSessionId,
            isLoggedIn: appState.isLoggedIn,
            email: CredentialStore.shared.email,
            onSelectSession: { session in
                viewModel.selectSession(session)
                viewState.isDrawerOpen = false
            },
            onDeleteSession: { session in
                viewState.deleteSession = session
            },
            onSync: {
                viewModel.syncNow(showErrors: true, showSuccess: true)
            },
            onOpenSettings: {
                viewState.isDrawerOpen = false
                viewState.showSettings = true
            }
        )
        .frame(width: drawerWidth)

        if isPinned {
            drawer
        } else {
            drawer
                .offset(x: viewState.isDrawerOpen ? 0 : drawerHiddenOffset)
                .animation(.easeOut(duration: 0.25), value: viewState.isDrawerOpen)
        }
    }

    private func handleToastTrigger(_ trigger: ToastTrigger) {
        if let message = trigger.syncError {
            showToast(message, duration: 2)
            viewModel.syncErrorMessage = nil
            return
        }
        if let message = trigger.syncSuccess {
            showToast(message, duration: 2)
            viewModel.syncSuccessMessage = nil
            return
        }
        if let message = trigger.generationError {
            showToast(message, duration: 2)
            viewModel.generationErrorMessage = nil
        }
    }

    private func showToast(_ text: String, duration: TimeInterval) {
        viewState.toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            viewState.toastMessage = ToastMessage(text: text)
        }
        let nanoseconds = UInt64(max(0, duration) * 1_000_000_000)
        viewState.toastTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }
            withAnimation(.easeIn(duration: 0.2)) {
                viewState.toastMessage = nil
            }
            viewState.toastTask = nil
        }
    }

    private func requestInputFocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isInputFocused = true
        }
    }

    private func handleSignInRequest() {
        if EnsuFeatureFlags.enableSignIn {
            isShowingAuth = true
        } else {
            viewState.showSignInComingSoon = true
        }
    }
}

private final class ChatViewState: ObservableObject {
    @Published var isDrawerOpen = false
    @Published var showSettings = false
    @Published var toastMessage: ToastMessage?
    @Published var deleteSession: ChatSession?
    @Published var showAttachmentDownloads = false
    @Published var showSignInComingSoon = false
    @Published var pendingSignInRequest = false
    @Published var didAutoFocusInput = false
    @Published var inputBarHeight: CGFloat = 0
    @Published var wasDrawerOpen = false
    @Published var didDismissKeyboard = false
    @Published var sessionTransitionId = UUID()

    var toastTask: Task<Void, Never>?
}

private struct ToastTrigger: Equatable {
    let syncError: String?
    let syncSuccess: String?
    let generationError: String?
}

private struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
}

#else
import SwiftUI

struct ChatView: View {
    var body: some View {
        Text("Chat unavailable")
    }
}
#endif
