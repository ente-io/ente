import SwiftUI

struct PasswordView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let onNavigate: (AuthRoute) -> Void
    let onLoggedIn: () -> Void

    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    private var hasPassword: Bool {
        !password.isEmpty
    }

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
                    Task { await loginTapped() }
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
                text: "Log in",
                isLoading: isLoading,
                isEnabled: hasPassword && !isLoading
            ) {
                Task { await loginTapped() }
            }
        }
    }

    @MainActor
    private func loginTapped() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await EnsuAuthService.shared.loginWithSrp(
                email: email,
                password: password,
                srpAttributes: srpAttributes
            )

            if result.requiresPasskey {
                onNavigate(
                    .passkey(
                        email: email,
                        srp: srpAttributes,
                        sessionId: result.passkeySessionId!,
                        accountsUrl: result.accountsUrl ?? "https://accounts.ente.io",
                        twoFactorSessionId: result.twoFactorSessionId,
                        password: password
                    )
                )
                return
            }

            if result.requiresTwoFactor {
                onNavigate(
                    .twoFactor(
                        email: email,
                        srp: srpAttributes,
                        sessionId: result.twoFactorSessionId!,
                        password: password
                    )
                )
                return
            }

            onLoggedIn()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
