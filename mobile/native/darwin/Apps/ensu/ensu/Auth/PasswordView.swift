import SwiftUI

#if canImport(EnteCore)
struct PasswordView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let onNavigate: (AuthRoute) -> Void
    let onLoggedIn: () -> Void

    @State private var password: String = ""
    @StateObject private var actionState = AuthActionState()
    @State private var showPassword = false

    var body: some View {
        PasswordEntryView(
            title: "Enter password",
            subtitle: email,
            buttonText: "Log in",
            password: $password,
            showPassword: $showPassword,
            isLoading: actionState.isLoading,
            errorMessage: actionState.errorMessage,
            onSubmit: loginTapped
        )
    }

    @MainActor
    private func loginTapped() async {
        await actionState.run {
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
        }
    }
}
#else
struct PasswordView: View {
    var body: some View {
        Text("Authentication unavailable")
    }
}
#endif
