import SwiftUI

struct OtpVerificationView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let onNavigate: (AuthRoute) -> Void

    @State private var code: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var hasValidCode: Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines).count == 6
    }

    var body: some View {
        AuthScreen {
            AuthHeader(title: "Verify email", subtitle: email)

            VStack(spacing: EnsuSpacing.lg) {
                CodeTextField(code: $code) { value in
                    if value.count == 6 {
                        Task { await verifyTapped() }
                    }
                }

                TextLink(text: "Resend code") {
                    Task { await resendTapped() }
                }
                .frame(maxWidth: .infinity)

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
            let payload = try await EnsuAuthService.shared.verifyOtp(email: email, otp: code)

            guard let keyAttrs = payload.keyAttributes else {
                errorMessage = "New user signup not implemented. Please use an existing account."
                return
            }

            if payload.requiresPasskey {
                onNavigate(
                    .passkey(
                        email: email,
                        srp: srpAttributes,
                        sessionId: payload.passkeySessionId!,
                        accountsUrl: payload.accountsUrl ?? "https://accounts.ente.io",
                        twoFactorSessionId: payload.twoFactorSessionId,
                        password: nil
                    )
                )
                return
            }

            if payload.requiresTwoFactor {
                onNavigate(
                    .twoFactor(
                        email: email,
                        srp: srpAttributes,
                        sessionId: payload.twoFactorSessionId!,
                        password: nil
                    )
                )
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

    @MainActor
    private func resendTapped() async {
        do {
            try await EnsuAuthService.shared.sendOtp(email: email)
        } catch {
            errorMessage = "Failed to resend code: \(error.localizedDescription)"
        }
    }
}
