import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isShowingAuth: Bool

    @EnvironmentObject private var appState: EnsuAppState

    @State private var isDrawerOpen = false
    @State private var showModelSettings = false
    @State private var rawMessage: ChatMessage?
    @State private var toastMessage: ToastMessage?
    @State private var deleteSession: ChatSession?
    @State private var developerTapCount = 0
    @State private var lastDeveloperTapAt: Date?
    @State private var isOpeningDeveloperSettings = false
    @State private var showDeveloperAlert = false
    @State private var showDeveloperSettings = false
    @State private var showSignOutAlert = false

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

                    if isDrawerOpen {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                            .onTapGesture { isDrawerOpen = false }
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
        }
        .sheet(isPresented: $showModelSettings) {
            ModelSettingsView()
        }
        .platformFullScreenCover(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView { message in
                showToast(message, duration: 2)
            }
        }
        .sheet(item: $rawMessage) { message in
            RawMessageDialog(text: message.text)
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
        .alert("Sign out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                appState.logout()
                isDrawerOpen = false
            }
            Button("Cancel", role: .cancel) {
                isDrawerOpen = false
            }
        } message: {
            Text("Are you sure you want to sign out?")
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
                title: "ensu",
                sessionTitle: viewModel.currentSession?.title ?? "New chat",
                showBrand: viewModel.messages.isEmpty,
                showSignIn: !appState.isLoggedIn,
                showsMenuButton: showsMenuButton,
                onMenu: { isDrawerOpen.toggle() },
                onSignIn: { isShowingAuth = true }
            )

            Divider()
                .background(EnsuColor.border)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    MessageListView(
                        messages: viewModel.messages,
                        streamingResponse: viewModel.streamingResponse,
                        isGenerating: viewModel.isGenerating,
                        onEdit: { message in
                            viewModel.beginEditing(message: message)
                        },
                        onCopy: { message in
                            copyToPasteboard(message.text)
                            showToast("Copied to clipboard", duration: 1)
                        },
                        onShowRaw: { message in
                            rawMessage = message
                        },
                        onRetry: { message in
                            viewModel.retryAssistantResponse(message)
                        },
                        onBranchChange: { message, delta in
                            viewModel.changeBranch(for: message, delta: delta)
                        }
                    )

                    MessageInputView(
                        text: $viewModel.draftText,
                        attachments: $viewModel.draftAttachments,
                        isGenerating: viewModel.isGenerating,
                        isDownloading: viewModel.isDownloading,
                        editingMessage: editingMessage,
                        isProcessingAttachments: viewModel.isProcessingAttachments,
                        onSend: {
                            viewModel.sendDraft()
                        },
                        onStop: {
                            viewModel.stopGenerating()
                        },
                        onCancelEdit: {
                            viewModel.cancelEditing()
                        },
                        onAddAttachment: { kind in
                            viewModel.addAttachment(kind: kind)
                        },
                        onRemoveAttachment: { attachment in
                            viewModel.removeAttachment(attachment)
                        }
                    )
                }

                if let downloadToast = viewModel.downloadToast {
                    DownloadToastView(state: downloadToast) {
                        viewModel.downloadToast = nil
                    } onRetry: {
                        viewModel.simulateDownload()
                    }
                    .padding(.top, EnsuSpacing.lg)
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
                viewModel.simulateDownload()
            },
            onShowLogs: {
                showToast("Logs are not available yet.", duration: 2)
            },
            onShowModelSettings: {
                showModelSettings = true
            },
            onDeveloperTap: {
                handleDeveloperTap()
            },
            onDeveloperSettings: {
                presentDeveloperPrompt()
            },
            onSignOut: {
                showSignOutAlert = true
            },
            onSignIn: {
                isDrawerOpen = false
                isShowingAuth = true
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

    private func handleDeveloperTap() {
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

private struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
}

private struct ChatAppBar: View {
    let title: String
    let sessionTitle: String
    let showBrand: Bool
    let showSignIn: Bool
    let showsMenuButton: Bool
    let onMenu: () -> Void
    let onSignIn: () -> Void

    private let centerInset: CGFloat = 72

    var body: some View {
        ZStack {
            HStack(spacing: EnsuSpacing.md) {
                if showsMenuButton {
                    Button(action: onMenu) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 40, height: 40)
                }

                Spacer()

                if showSignIn {
                    Button(action: onSignIn) {
                        Text("Sign In")
                            .font(EnsuTypography.small)
                            .foregroundStyle(EnsuColor.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(showBrand ? title : sessionTitle)
                .font(showBrand ? EnsuTypography.h3Bold : EnsuTypography.large)
                .foregroundStyle(EnsuColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, centerInset)
        }
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
        .padding(.vertical, EnsuSpacing.sm)
        .background(EnsuColor.backgroundBase)
    }
}
