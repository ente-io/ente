import SwiftUI

#if canImport(EnteCore)
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

struct AuthErrorText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(EnsuTypography.small)
            .foregroundStyle(EnsuColor.error)
            .padding(.horizontal, EnsuSpacing.pageHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
final class AuthActionState: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func setError(_ message: String?) {
        errorMessage = message
    }

    func run(
        onError: ((Error) -> String)? = nil,
        _ action: @escaping () async throws -> Void
    ) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await action()
        } catch {
            errorMessage = onError?(error) ?? error.localizedDescription
        }
    }
}

struct StyledTextField: View {
    let hint: String
    @Binding var text: String
    var keyboardType: PlatformKeyboardType = .default
    var textContentType: PlatformTextContentType? = nil
    var autocapitalization: PlatformTextInputAutocapitalization = .never
    var isSecure: Bool = false
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    var body: some View {
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

            StyledTextField(
                hint: hint,
                text: $text,
                keyboardType: keyboardType,
                textContentType: textContentType,
                autocapitalization: autocapitalization,
                isSecure: isSecure,
                submitLabel: submitLabel,
                onSubmit: onSubmit
            )
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
                    Image(showPassword ? "ViewOffSlashIcon" : "ViewIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
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

struct PasswordEntryView: View {
    let title: String
    let subtitle: String
    let buttonText: String
    @Binding var password: String
    @Binding var showPassword: Bool
    let isLoading: Bool
    let errorMessage: String?
    var submitLabel: SubmitLabel = .go
    let onSubmit: () async -> Void

    private var hasPassword: Bool { !password.isEmpty }

    var body: some View {
        AuthScreen {
            AuthHeader(title: title)
            AuthSubtitle(text: subtitle)

            VStack(spacing: EnsuSpacing.xxl) {
                PasswordTextField(
                    label: "Password",
                    hint: "Enter your password",
                    text: $password,
                    showPassword: $showPassword,
                    submitLabel: submitLabel
                ) {
                    Task { await onSubmit() }
                }

                if let errorMessage {
                    AuthErrorText(message: errorMessage)
                }
            }
            .padding(.top, EnsuSpacing.xxl)
        } bottom: {
            PrimaryButton(
                text: buttonText,
                isLoading: isLoading,
                isEnabled: hasPassword && !isLoading
            ) {
                Task { await onSubmit() }
            }
        }
    }
}

struct VerificationCodeView<Accessory: View>: View {
    let title: String
    let subtitle: String?
    @Binding var code: String
    let buttonText: String
    let isLoading: Bool
    let errorMessage: String?
    var autoSubmitLength: Int = 6
    let onSubmit: () async -> Void
    @ViewBuilder let accessory: () -> Accessory

    private var hasValidCode: Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines).count == autoSubmitLength
    }

    init(
        title: String,
        subtitle: String? = nil,
        code: Binding<String>,
        buttonText: String = "Verify",
        isLoading: Bool,
        errorMessage: String?,
        autoSubmitLength: Int = 6,
        onSubmit: @escaping () async -> Void,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self._code = code
        self.buttonText = buttonText
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.autoSubmitLength = autoSubmitLength
        self.accessory = accessory
        self.onSubmit = onSubmit
    }

    var body: some View {
        AuthScreen {
            AuthHeader(title: title, subtitle: subtitle)

            VStack(spacing: EnsuSpacing.lg) {
                CodeTextField(code: $code, maxLength: autoSubmitLength) { value in
                    if value.count == autoSubmitLength {
                        Task { await onSubmit() }
                    }
                }

                accessory()

                if let errorMessage {
                    AuthErrorText(message: errorMessage)
                }
            }
        } bottom: {
            PrimaryButton(
                text: buttonText,
                isLoading: isLoading,
                isEnabled: hasValidCode && !isLoading
            ) {
                Task { await onSubmit() }
            }
        }
    }
}

extension VerificationCodeView where Accessory == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        code: Binding<String>,
        buttonText: String = "Verify",
        isLoading: Bool,
        errorMessage: String?,
        autoSubmitLength: Int = 6,
        onSubmit: @escaping () async -> Void
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            code: code,
            buttonText: buttonText,
            isLoading: isLoading,
            errorMessage: errorMessage,
            autoSubmitLength: autoSubmitLength,
            onSubmit: onSubmit,
            accessory: { EmptyView() }
        )
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
#endif
