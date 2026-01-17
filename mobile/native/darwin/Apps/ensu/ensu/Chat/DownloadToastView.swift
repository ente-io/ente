import SwiftUI

struct DownloadToastView: View {
    let state: DownloadToastState
    let onDismiss: () -> Void
    let onRetry: () -> Void

    private var isComplete: Bool {
        state.phase == .complete
    }

    private var hasError: Bool {
        state.phase == .errorDownload || state.phase == .errorLoad
    }

    private var title: String {
        switch state.phase {
        case .downloading:
            return "Downloading model"
        case .loading:
            return "Loading model"
        case .complete:
            return "Model ready"
        case .errorDownload:
            return "Model setup failed"
        case .errorLoad:
            return "Model loading failed"
        }
    }

    private var iconName: String {
        switch state.phase {
        case .downloading:
            return "arrow.down.circle"
        case .loading:
            return "cpu"
        case .complete:
            return "checkmark.circle.fill"
        case .errorDownload, .errorLoad:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch state.phase {
        case .complete:
            return EnsuColor.success
        case .errorDownload, .errorLoad:
            return EnsuColor.error
        default:
            return EnsuColor.textPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
            HStack(spacing: EnsuSpacing.md) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(EnsuTypography.large)
                    .foregroundStyle(EnsuColor.textPrimary)

                Spacer()

                if !isComplete && !hasError {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(EnsuColor.textMuted)
                }
            }

            if !hasError {
                ProgressView(value: Double(state.percent) / 100)
                    .progressViewStyle(.linear)
                    .tint(isComplete ? EnsuColor.success : EnsuColor.accent)
                    .frame(height: 4)
                    .background(EnsuColor.border)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            }

            HStack {
                Text(state.status)
                    .font(EnsuFont.message(size: 12, weight: .regular))
                    .foregroundStyle(hasError ? EnsuColor.error : EnsuColor.textMuted)

                Spacer()

                if !isComplete {
                    Text("\(state.percent)%")
                        .font(EnsuTypography.mini)
                        .foregroundStyle(EnsuColor.textMuted)
                }
            }

            if hasError {
                HStack {
                    Spacer()
                    Button("Dismiss", action: onDismiss)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                    Button(state.offerRetryDownload ? "Retry download" : "Retry", action: onRetry)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.accent)
                }
            }
        }
        .padding(EnsuSpacing.lg)
        .background(EnsuColor.fillFaint)
        .overlay(
            RoundedRectangle(cornerRadius: EnsuCornerRadius.toast)
                .stroke(EnsuColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.toast, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .padding(.horizontal, EnsuSpacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
