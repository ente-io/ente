import SwiftUI

#if canImport(EnteCore)
struct TwoFactorView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let sessionId: String
    let password: String?
    let onNavigate: (AuthRoute) -> Void
    let onLoggedIn: () -> Void

    @State private var code: String = ""
    @StateObject private var actionState = AuthActionState()

    var body: some View {
        VerificationCodeView(
            title: "Two-factor authentication",
            subtitle: "Enter the code from your authenticator app",
            code: $code,
            buttonText: "Verify",
            isLoading: actionState.isLoading,
            errorMessage: actionState.errorMessage,
            onSubmit: verifyTapped
        )
    }

    @MainActor
    private func verifyTapped() async {
        await actionState.run {
            let payload = try await EnsuAuthService.shared.verifyTwoFactor(sessionId: sessionId, code: code)
            guard let keyAttrs = payload.keyAttributes else {
                actionState.setError("Invalid response")
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
        }
    }
}
#else
struct TwoFactorView: View {
    var body: some View {
        Text("Authentication unavailable")
    }
}
#endif
