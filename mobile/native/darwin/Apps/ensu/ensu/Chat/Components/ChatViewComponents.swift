#if canImport(EnteCore)
import SwiftUI

struct DownloadOnboardingView: View {
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
                        return "Downloading... \(downloaded.formattedFileSize) / \(totalBytes.formattedFileSize)"
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
                .foregroundStyle(Color.black)
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
                .tint(EnsuColor.action)
                .frame(maxWidth: 240)
        } else {
            ProgressView()
                .progressViewStyle(.linear)
                .tint(EnsuColor.action)
                .frame(maxWidth: 240)
        }
    }

}

struct SignInComingSoonDialog: View {
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: EnsuSpacing.lg) {
                Image("EnsuDucky")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                Text(title)
                    .font(EnsuTypography.large)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)
                    .multilineTextAlignment(.center)

                Button(action: {
                    hapticTap()
                    onDismiss()
                }) {
                    Text("Got it")
                        .font(EnsuTypography.body)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, EnsuSpacing.md)
                        .background(EnsuColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(EnsuSpacing.lg)
            .frame(maxWidth: 360)
            .background(EnsuColor.backgroundBase)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
            .padding(.horizontal, EnsuSpacing.pageHorizontal)
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        }
    }
}

struct AttachmentDownloadsSheet: View {
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
                    .foregroundStyle(EnsuColor.action)
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

struct ChatAppBar: View {
    let sessionTitle: String
    let showBrand: Bool
    let showSignIn: Bool
    let showsMenuButton: Bool
    let attachmentDownloadSummary: (completed: Int, total: Int)?
    let modelDownloadState: DownloadToastState?
    let onMenu: () -> Void
    let onSignIn: () -> Void
    let onNewChat: () -> Void
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
                                .foregroundStyle(EnsuColor.action)
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

                    Button(action: {
                        hapticTap()
                        onNewChat()
                    }) {
                        Image("PlusSignIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(EnsuColor.textPrimary)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showBrand {
                EnsuLogo(height: 21)
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

struct ModelProgressIndicator: View {
    let state: DownloadToastState

    var body: some View {
        let clamped = min(max(state.percent, 0), 100)
        if state.phase == .downloading {
            ProgressView(value: Double(clamped), total: 100)
                .progressViewStyle(.circular)
                .tint(EnsuColor.action)
                .frame(width: 16, height: 16)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(EnsuColor.action)
                .frame(width: 16, height: 16)
        }
    }
}
#endif
