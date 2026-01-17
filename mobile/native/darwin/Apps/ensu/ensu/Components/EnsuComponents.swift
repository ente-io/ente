import SwiftUI

struct PrimaryButton: View {
    let text: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(text)
                        .font(EnsuFont.ui(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, EnsuSpacing.buttonVertical)
        }
        .buttonStyle(.plain)
        .background(EnsuColor.accentGradient)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.button, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.button, style: .continuous))
        .opacity(isEnabled ? 1 : 0.5)
        .allowsHitTesting(isEnabled && !isLoading)
    }
}

struct TextLink: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(EnsuFont.ui(size: 14, weight: .semibold))
                .underline()
        }
        .buttonStyle(.plain)
        .foregroundStyle(EnsuColor.accent)
    }
}

struct ActionButton: View {
    let icon: String
    var tooltip: String? = nil
    var color: Color = EnsuColor.textMuted
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(ActionButtonStyle(color: color))
        .accessibilityLabel(tooltip ?? "")
    }
}

struct TextActionButton: View {
    let text: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(EnsuTypography.small)
                .foregroundStyle(isEnabled ? EnsuColor.textMuted : EnsuColor.textMuted.opacity(0.4))
                .padding(.horizontal, 4)
                .frame(height: 36)
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(color)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(configuration.isPressed ? EnsuColor.fillFaint : Color.clear)
            )
    }
}

struct AttachmentChip: View {
    let name: String
    let size: String
    let icon: String
    var isUploading: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(EnsuColor.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(EnsuTypography.small)
                    .foregroundStyle(EnsuColor.textPrimary)
                    .lineLimit(1)
                Text(size)
                    .font(EnsuTypography.mini)
                    .foregroundStyle(EnsuColor.textMuted)
            }

            if isUploading {
                ProgressView()
                    .scaleEffect(0.7)
            }

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(EnsuColor.fillFaint)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(EnsuTypography.body)
            .foregroundStyle(EnsuColor.toastText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(EnsuColor.toastBackground)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.toast, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct MacSheetHeader<Leading: View, Center: View, Trailing: View>: View {
    let leading: Leading
    let center: Center
    let trailing: Trailing

    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            center

            HStack {
                leading
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
        .padding(.vertical, EnsuSpacing.sm)
        .background(EnsuColor.backgroundBase)
    }
}
