import SwiftUI

#if canImport(EnteCore)
struct EmailEntryView: View {
    let onNavigate: (AuthRoute) -> Void

    @State private var email: String = ""
    @StateObject private var actionState = AuthActionState()

    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    var body: some View {
        AuthScreen {
            AuthHeader(title: "Welcome back")

            VStack(spacing: EnsuSpacing.lg) {
                LabeledTextField(
                    label: "Email",
                    hint: "Enter your email",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    submitLabel: .next
                ) {
                    Task { await continueTapped() }
                }

                if let errorMessage = actionState.errorMessage {
                    AuthErrorText(message: errorMessage)
                }
            }
        } bottom: {
            PrimaryButton(
                text: "Log in",
                isLoading: actionState.isLoading,
                isEnabled: isEmailValid && !actionState.isLoading
            ) {
                Task { await continueTapped() }
            }
        }
    }

    @MainActor
    private func continueTapped() async {
        await actionState.run(onError: { error in
            "Failed to get account info: \(error.localizedDescription)"
        }) {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let srpAttrs = try await EnsuAuthService.shared.getSrpAttributes(email: trimmedEmail)

            if srpAttrs.isEmailMfaEnabled {
                try await EnsuAuthService.shared.sendOtp(email: trimmedEmail)
                onNavigate(.otp(email: trimmedEmail, srp: srpAttrs))
            } else {
                onNavigate(.password(email: trimmedEmail, srp: srpAttrs))
            }
        }
    }
}
#else
struct EmailEntryView: View {
    var body: some View {
        Text("Authentication unavailable")
    }
}
#endif
