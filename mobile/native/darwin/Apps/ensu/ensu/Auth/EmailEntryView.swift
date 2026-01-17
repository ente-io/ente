import SwiftUI

struct EmailEntryView: View {
    let onNavigate: (AuthRoute) -> Void

    @State private var email: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                text: "Log in",
                isLoading: isLoading,
                isEnabled: isEmailValid && !isLoading
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

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let srpAttrs = try await EnsuAuthService.shared.getSrpAttributes(email: trimmedEmail)

            if srpAttrs.isEmailMfaEnabled {
                try await EnsuAuthService.shared.sendOtp(email: trimmedEmail)
                onNavigate(.otp(email: trimmedEmail, srp: srpAttrs))
            } else {
                onNavigate(.password(email: trimmedEmail, srp: srpAttrs))
            }
        } catch {
            errorMessage = "Failed to get account info: \(error.localizedDescription)"
        }
    }
}
