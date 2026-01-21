import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isShowingAuth: Bool

    @EnvironmentObject private var appState: EnsuAppState

    @State private var isDrawerOpen = false
    @State private var showModelSettings = false
    @State private var toastMessage: ToastMessage?
    @State private var deleteSession: ChatSession?
    @State private var developerTapCount = 0
    @State private var lastDeveloperTapAt: Date?
    @State private var isOpeningDeveloperSettings = false
    @State private var showDeveloperAlert = false
    @State private var showDeveloperSettings = false
    @State private var showSignOutAlert = false
    @State private var showAttachmentDownloads = false

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
            .onChange(of: viewModel.syncErrorMessage) { message in
                guard let message else { return }
                showToast(message, duration: 2)
                viewModel.syncErrorMessage = nil
            }
        }
        .sheet(isPresented: $showModelSettings) {
            ModelSettingsView()
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
                sessionTitle: viewModel.currentSession?.title ?? "New chat",
                showBrand: viewModel.messages.isEmpty,
                showSignIn: !appState.isLoggedIn,
                showsMenuButton: showsMenuButton,
                attachmentDownloadSummary: viewModel.attachmentDownloadSummary,
                onMenu: { isDrawerOpen.toggle() },
                onSignIn: { isShowingAuth = true },
                onAttachmentDownloads: {
                    showAttachmentDownloads = true
                }
            )

            Divider()
                .background(EnsuColor.border)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    MessageListView(
                        messages: viewModel.messages,
                        streamingResponse: viewModel.displayedStreamingResponse,
                        streamingParentId: viewModel.displayedStreamingParentId,
                        isGenerating: viewModel.isGenerating,
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
                        }
                    )

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
                        }
                    )
                }

                if let downloadToast = viewModel.downloadToast {
                    DownloadToastView(state: downloadToast) {
                        viewModel.downloadToast = nil
                    } onRetry: {
                        viewModel.retryDownload()
                    } onCancel: {
                        viewModel.cancelDownload()
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
                viewModel.syncNow()
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
                            Button(action: { onCancel(item.id) }) {
                                Image(systemName: "xmark.circle.fill")
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
    let onMenu: () -> Void
    let onSignIn: () -> Void
    let onAttachmentDownloads: () -> Void

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
                } else if let summary = attachmentDownloadSummary {
                    Button(action: onAttachmentDownloads) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 14, weight: .semibold))
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
