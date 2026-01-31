import SwiftUI

#if canImport(EnteCore)
struct PasswordAfterMfaView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let userId: Int64
    let keyAttributes: KeyAttributes
    let encryptedToken: String?
    let token: String?
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
            try await EnsuAuthService.shared.loginAfterChallenge(
                email: email,
                password: password,
                srpAttributes: srpAttributes,
                userId: userId,
                keyAttributes: keyAttributes,
                encryptedToken: encryptedToken,
                token: token
            )
            onLoggedIn()
        }
    }
}
#else
struct PasswordAfterMfaView: View {
    var body: some View {
        Text("Authentication unavailable")
    }
}
#endif
