import SwiftUI

struct TwoFactorView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let sessionId: String
    let password: String?
    let onNavigate: (AuthRoute) -> Void
    let onLoggedIn: () -> Void

    @State private var code: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var hasValidCode: Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines).count == 6
    }

    var body: some View {
        AuthScreen {
            AuthHeader(
                title: "Two-factor authentication",
                subtitle: "Enter the code from your authenticator app"
            )

            VStack(spacing: EnsuSpacing.lg) {
                CodeTextField(code: $code) { value in
                    if value.count == 6 {
                        Task { await verifyTapped() }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.error)
                        .padding(.horizontal, EnsuSpacing.pageHorizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } bottom: {
            PrimaryButton(
                text: "Verify",
                isLoading: isLoading,
                isEnabled: hasValidCode && !isLoading
            ) {
                Task { await verifyTapped() }
            }
        }
    }

    @MainActor
    private func verifyTapped() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let payload = try await EnsuAuthService.shared.verifyTwoFactor(sessionId: sessionId, code: code)
            guard let keyAttrs = payload.keyAttributes else {
                errorMessage = "Invalid response"
                return
            }

            if let password, !password.isEmpty {
                try await EnsuAuthService.shared.loginAfterChallenge(
                    email: email,
                    password: password,
                    srpAttributes: srpAttributes,
                    userId: payload.userId,
                    keyAttributes: keyAttrs,
                    encryptedToken: payload.encryptedToken,
                    token: payload.token
                )
                onLoggedIn()
                return
            }

            onNavigate(
                .passwordAfterMfa(
                    email: email,
                    srp: srpAttributes,
                    userId: payload.userId,
                    keyAttributes: keyAttrs,
                    encryptedToken: payload.encryptedToken,
                    token: payload.token
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
