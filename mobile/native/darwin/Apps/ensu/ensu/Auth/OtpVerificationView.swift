import SwiftUI

#if canImport(EnteCore)
struct OtpVerificationView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let onNavigate: (AuthRoute) -> Void

    @State private var code: String = ""
    @StateObject private var actionState = AuthActionState()

    var body: some View {
        VerificationCodeView(
            title: "Verify email",
            subtitle: email,
            code: $code,
            buttonText: "Verify",
            isLoading: actionState.isLoading,
            errorMessage: actionState.errorMessage,
            onSubmit: verifyTapped
        ) {
            TextLink(text: "Resend code") {
                Task { await resendTapped() }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @MainActor
    private func verifyTapped() async {
        await actionState.run {
            let payload = try await EnsuAuthService.shared.verifyOtp(email: email, otp: code)

            guard let keyAttrs = payload.keyAttributes else {
                actionState.setError("New user signup not implemented. Please use an existing account.")
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
        }
    }

    @MainActor
    private func resendTapped() async {
        do {
            try await EnsuAuthService.shared.sendOtp(email: email)
        } catch {
            actionState.setError("Failed to resend code: \(error.localizedDescription)")
        }
    }
}
#else
struct OtpVerificationView: View {
    var body: some View {
        Text("Authentication unavailable")
    }
}
#endif
