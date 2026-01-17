import SwiftUI

struct PasskeyPasswordReentryView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let auth: AuthResponsePayload
    let onLoggedIn: () -> Void

    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    private var hasPassword: Bool { !password.isEmpty }

    var body: some View {
        AuthScreen {
            AuthHeader(title: "Enter password")
            AuthSubtitle(text: email)

            VStack(spacing: EnsuSpacing.xxl) {
                PasswordTextField(
                    label: "Password",
                    hint: "Enter your password",
                    text: $password,
                    showPassword: $showPassword,
                    submitLabel: .go
                ) {
                    Task { await continueTapped() }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.error)
                        .padding(.horizontal, EnsuSpacing.pageHorizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, EnsuSpacing.xxl)
        } bottom: {
            PrimaryButton(
                text: "Continue",
                isLoading: isLoading,
                isEnabled: hasPassword && !isLoading
            ) {
                Task { await continueTapped() }
            }
        }
    }

    @MainActor
    private func continueTapped() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        guard let keyAttrs = auth.keyAttributes else {
            errorMessage = "Invalid passkey response."
            return
        }

        do {
            try await EnsuAuthService.shared.loginAfterChallenge(
                email: email,
                password: password,
                srpAttributes: srpAttributes,
                userId: auth.userId,
                keyAttributes: keyAttrs,
                encryptedToken: auth.encryptedToken,
                token: auth.token
            )
            onLoggedIn()
        } catch {
            errorMessage = "Incorrect password: \(error.localizedDescription)"
        }
    }
}
