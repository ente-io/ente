import SwiftUI

struct PasswordAfterMfaView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let userId: Int64
    let keyAttributes: KeyAttributes
    let encryptedToken: String?
    let token: String?
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

        do {
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
        } catch {
            errorMessage = "Incorrect password: \(error.localizedDescription)"
        }
    }
}
