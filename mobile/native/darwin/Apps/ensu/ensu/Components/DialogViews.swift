import SwiftUI

enum ChoiceDialogButtonType {
    case normal
    case critical
    case neutral

    var color: Color {
        switch self {
        case .critical:
            return EnsuColor.error
        case .neutral:
            return EnsuColor.textMuted
        case .normal:
            return EnsuColor.accent
        }
    }
}

struct ChoiceDialog: View {
    let title: String
    let bodyText: String
    let firstButtonLabel: String
    let secondButtonLabel: String?
    let firstButtonType: ChoiceDialogButtonType
    let isDismissible: Bool
    let onFirst: () -> Void
    let onSecond: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        body: String,
        firstButtonLabel: String,
        secondButtonLabel: String? = nil,
        firstButtonType: ChoiceDialogButtonType = .normal,
        isDismissible: Bool = true,
        onFirst: @escaping () -> Void,
        onSecond: (() -> Void)? = nil
    ) {
        self.title = title
        self.bodyText = body
        self.firstButtonLabel = firstButtonLabel
        self.secondButtonLabel = secondButtonLabel
        self.firstButtonType = firstButtonType
        self.isDismissible = isDismissible
        self.onFirst = onFirst
        self.onSecond = onSecond
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.md) {
            Text(title)
                .font(EnsuTypography.h3)
                .foregroundStyle(EnsuColor.textPrimary)

            Text(bodyText)
                .font(EnsuTypography.body)
                .foregroundStyle(EnsuColor.textPrimary)

            HStack {
                if let secondButtonLabel {
                    Button(secondButtonLabel) {
                        onSecond?()
                        dismissIfNeeded()
                    }
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)
                }

                Spacer()

                Button(firstButtonLabel) {
                    onFirst()
                    dismissIfNeeded()
                }
                .font(EnsuTypography.body)
                .foregroundStyle(firstButtonType.color)
            }
        }
        .padding(EnsuSpacing.lg)
        .background(EnsuColor.backgroundBase)
        .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.card, style: .continuous))
    }

    private func dismissIfNeeded() {
        if isDismissible {
            dismiss()
        }
    }
}

struct MissingAttachmentsSheet: View {
    let missingCount: Int
    let allowDownload: Bool
    let onDownload: () -> Void
    let onRunWithout: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.md) {
            Text("Attachments missing")
                .font(EnsuTypography.large)
                .foregroundStyle(EnsuColor.textPrimary)

            Text("\(missingCount) attachment(s) are missing and need to be downloaded")
                .font(EnsuTypography.body)
                .foregroundStyle(EnsuColor.textPrimary)

            if allowDownload {
                PrimaryButton(text: "Download attachments") {
                    onDownload()
                }
            }

            Button("Run without") {
                onRunWithout()
            }
            .font(EnsuTypography.body)
            .foregroundStyle(EnsuColor.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, EnsuSpacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: EnsuCornerRadius.button)
                    .stroke(EnsuColor.border, lineWidth: 1)
            )

            Button("Cancel") {
                onCancel()
            }
            .font(EnsuTypography.body)
            .foregroundStyle(EnsuColor.textMuted)
        }
        .padding(EnsuSpacing.lg)
        .presentationDetents([.medium])
    }
}
