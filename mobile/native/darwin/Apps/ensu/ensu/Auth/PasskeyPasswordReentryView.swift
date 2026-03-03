import SwiftUI

#if canImport(EnteCore)
struct PasskeyPasswordReentryView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let auth: AuthResponsePayload
    let onLoggedIn: () -> Void

    @State private var password: String = ""
    @StateObject private var actionState = AuthActionState()
    @State private var showPassword = false

    var body: some View {
        PasswordEntryView(
            title: "Enter password",
            subtitle: email,
            buttonText: "Continue",
            password: $password,
            showPassword: $showPassword,
            isLoading: actionState.isLoading,
            errorMessage: actionState.errorMessage,
            onSubmit: continueTapped
        )
    }

    @MainActor
    private func continueTapped() async {
        await actionState.run(onError: { error in
            "Incorrect password: \(error.localizedDescription)"
        }) {
            guard let keyAttrs = auth.keyAttributes else {
                actionState.setError("Invalid passkey response.")
                return
            }

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
        }
    }
}
#else
struct PasskeyPasswordReentryView: View {
    var body: some View {
        Text("Authentication unavailable")
    }
}
#endif
