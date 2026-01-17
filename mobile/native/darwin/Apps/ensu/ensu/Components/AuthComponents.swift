import SwiftUI

struct AuthHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: EnsuSpacing.sm) {
            Text(title)
                .font(EnsuTypography.h2Bold)
                .foregroundStyle(EnsuColor.textPrimary)
                .lineSpacing(EnsuLineHeight.spacing(fontSize: 32, lineHeight: 1.2))

            if let subtitle {
                Text(subtitle)
                    .font(EnsuTypography.body)
                    .foregroundStyle(EnsuColor.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
        .padding(.vertical, EnsuSpacing.pageVertical)
    }
}

struct AuthSubtitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(EnsuTypography.body)
            .foregroundStyle(EnsuColor.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, EnsuSpacing.pageHorizontal)
    }
}

struct LabeledTextField: View {
    let label: String
    let hint: String
    @Binding var text: String
    var keyboardType: PlatformKeyboardType = .default
    var textContentType: PlatformTextContentType? = nil
    var autocapitalization: PlatformTextInputAutocapitalization = .never
    var isSecure: Bool = false
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)

            Group {
                if isSecure {
                    SecureField(hint, text: $text)
                } else {
                    TextField(hint, text: $text)
                }
            }
            .font(EnsuTypography.body)
            .foregroundStyle(EnsuColor.textPrimary)
            .platformTextFieldStyle()
            .platformTextInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .platformKeyboardType(keyboardType)
            .platformTextContentType(textContentType)
            .submitLabel(submitLabel)
            .onSubmit {
                onSubmit?()
            }
            .padding(.horizontal, EnsuSpacing.inputHorizontal)
            .padding(.vertical, EnsuSpacing.inputVertical)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
        }
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
    }
}

struct PasswordTextField: View {
    let label: String
    let hint: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(EnsuTypography.small)
                .foregroundStyle(EnsuColor.textMuted)

            HStack(spacing: 8) {
                Group {
                    if showPassword {
                        TextField(hint, text: $text)
                    } else {
                        SecureField(hint, text: $text)
                    }
                }
                .font(EnsuTypography.body)
                .foregroundStyle(EnsuColor.textPrimary)
                .platformTextFieldStyle()
                .platformTextInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .platformTextContentType(.password)
                .submitLabel(submitLabel)
                .onSubmit {
                    onSubmit?()
                }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(EnsuColor.textMuted)
                }
            }
            .padding(.horizontal, EnsuSpacing.inputHorizontal)
            .padding(.vertical, EnsuSpacing.inputVertical)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
        }
        .padding(.horizontal, EnsuSpacing.pageHorizontal)
    }
}

struct CodeTextField: View {
    @Binding var code: String
    var maxLength: Int = 6
    var onChange: ((String) -> Void)? = nil

    var body: some View {
        TextField("• • • • • •", text: $code)
            .platformKeyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(EnsuFont.ui(size: 28, weight: .medium))
            .foregroundStyle(EnsuColor.textPrimary)
            .platformTextFieldStyle()
            .tracking(8)
            .padding(.horizontal, EnsuSpacing.inputHorizontal)
            .padding(.vertical, EnsuSpacing.inputVertical)
            .background(EnsuColor.fillFaint)
            .clipShape(RoundedRectangle(cornerRadius: EnsuCornerRadius.input, style: .continuous))
            .padding(.horizontal, EnsuSpacing.pageHorizontal)
            .onChange(of: code) { newValue in
                var digits = newValue.filter { $0.isNumber }
                if digits.count > maxLength {
                    digits = String(digits.prefix(maxLength))
                }
                if digits != newValue {
                    code = digits
                }
                onChange?(digits)
            }
    }
}

struct AuthScreen<Content: View, Bottom: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let bottom: () -> Bottom

    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        VStack(spacing: 0) {
            content()
            Spacer()
            if !keyboard.isVisible {
                bottom()
                    .padding(.horizontal, EnsuSpacing.pageHorizontal)
                    .padding(.top, EnsuSpacing.md)
                    .padding(.bottom, EnsuSpacing.pageVertical)
            }
        }
        .background(EnsuColor.backgroundBase.ignoresSafeArea())
    }
}
