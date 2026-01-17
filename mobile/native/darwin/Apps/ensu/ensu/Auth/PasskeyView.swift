import SwiftUI

struct PasskeyView: View {
    let email: String
    let srpAttributes: SrpAttributes
    let sessionId: String
    let accountsUrl: String
    let twoFactorSessionId: String?
    let password: String?
    let onNavigate: (AuthRoute) -> Void
    let onLoggedIn: () -> Void

    private static let redirectUrl = "enteensu://passkey"
    private static let clientPackage = "io.ente.ensu"

    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @Environment(\.openURL) private var openURL

    @State private var isChecking = false
    @State private var message: String?

    var body: some View {
        AuthScreen {
            AuthHeader(
                title: "Passkey verification",
                subtitle: "Complete passkey verification in browser"
            )

            VStack(spacing: EnsuSpacing.lg) {
                TextLink(text: "Open passkey again") {
                    launchPasskey()
                }
                .frame(maxWidth: .infinity)

                if let twoFactorSessionId, !twoFactorSessionId.isEmpty {
                    TextLink(text: "Use authenticator code") {
                        onNavigate(
                            .twoFactor(
                                email: email,
                                srp: srpAttributes,
                                sessionId: twoFactorSessionId,
                                password: password
                            )
                        )
                    }
                    .frame(maxWidth: .infinity)
                }

                if let message {
                    Text(message)
                        .font(EnsuTypography.small)
                        .foregroundStyle(EnsuColor.textMuted)
                        .padding(.horizontal, EnsuSpacing.pageHorizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } bottom: {
            PrimaryButton(
                text: "Check status",
                isLoading: isChecking,
                isEnabled: !isChecking
            ) {
                Task { await checkStatusTapped() }
            }
        }
        .onAppear {
            launchPasskey()
        }
        .onChange(of: deepLinkRouter.lastURL) { newValue in
            guard let url = newValue else { return }
            Task { await handleDeepLink(url) }
        }
    }

    private func launchPasskey() {
        guard var components = URLComponents(string: accountsUrl) else {
            message = "Invalid accounts URL"
            return
        }

        let base = components.url?.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? accountsUrl
        guard var verifyComponents = URLComponents(string: base + "/passkeys/verify") else {
            message = "Invalid passkey URL"
            return
        }

        verifyComponents.queryItems = [
            URLQueryItem(name: "passkeySessionID", value: sessionId),
            URLQueryItem(name: "redirect", value: Self.redirectUrl),
            URLQueryItem(name: "clientPackage", value: Self.clientPackage),
        ]

        guard let url = verifyComponents.url else {
            message = "Invalid passkey URL"
            return
        }

        openURL(url)
    }

    @MainActor
    private func checkStatusTapped() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        do {
            let payload = try await EnsuAuthService.shared.getTokenForPasskeySession(sessionId: sessionId)
            try await handleAuthResponse(payload)
        } catch is PasskeySessionNotVerifiedError {
            message = "Passkey verification is still pending."
        } catch is PasskeySessionExpiredError {
            message = "Login session expired."
        } catch {
            message = "Failed to check passkey status: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func handleDeepLink(_ url: URL) async {
        guard url.scheme?.lowercased() == "enteensu" else { return }
        guard url.host?.lowercased() == "passkey" else { return }

        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let qp: [String: String] = Dictionary(uniqueKeysWithValues: params.compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })

        guard let sid = qp["passkeySessionID"], sid == sessionId else {
            message = "Session ID mismatch."
            return
        }

        guard let responseParam = qp["response"], !responseParam.isEmpty else {
            return
        }

        var base64 = responseParam
        while base64.count % 4 != 0 { base64.append("=") }
        guard let decodedData = Data(base64Encoded: base64) else {
            message = "Missing/invalid passkey response."
            return
        }

        do {
            let jsonAny = try JSONSerialization.jsonObject(with: decodedData)
            guard let json = jsonAny as? [String: Any] else {
                message = "Invalid passkey response."
                return
            }

            let payload = try parseAuthResponseJSON(json)
            try await handleAuthResponse(payload)
        } catch {
            message = "Failed to verify passkey."
        }
    }

    @MainActor
    private func handleAuthResponse(_ payload: AuthResponsePayload) async throws {
        guard let keyAttrs = payload.keyAttributes else {
            throw EnsuError.Message(message: "Invalid passkey response")
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

        onNavigate(.passkeyPasswordReentry(email: email, srp: srpAttributes, auth: payload))
    }

    private func parseAuthResponseJSON(_ json: [String: Any]) throws -> AuthResponsePayload {
        guard let id = json["id"] as? Int else {
            throw URLError(.badServerResponse)
        }

        let encryptedToken = json["encryptedToken"] as? String
        let token = json["token"] as? String

        let passkeySessionId = json["passkeySessionID"] as? String

        let twoFactorV2 = json["twoFactorSessionIDV2"] as? String
        let twoFactor = json["twoFactorSessionID"] as? String
        let twoFactorSessionId = (twoFactorV2?.isEmpty == false) ? twoFactorV2 : twoFactor

        let accountsUrl = json["accountsUrl"] as? String

        let keyAttrsDict = json["keyAttributes"] as? [String: Any]
        let keyAttrs = keyAttrsDict.flatMap { dict -> KeyAttributes? in
            guard
                let kekSalt = dict["kekSalt"] as? String,
                let encryptedKey = dict["encryptedKey"] as? String,
                let keyDecryptionNonce = dict["keyDecryptionNonce"] as? String,
                let publicKey = dict["publicKey"] as? String,
                let encryptedSecretKey = dict["encryptedSecretKey"] as? String,
                let secretKeyDecryptionNonce = dict["secretKeyDecryptionNonce"] as? String
            else {
                return nil
            }

            let memLimit = (dict["memLimit"] as? NSNumber).map { $0.uint32Value }
            let opsLimit = (dict["opsLimit"] as? NSNumber).map { $0.uint32Value }

            return KeyAttributes(
                kekSalt: kekSalt,
                encryptedKey: encryptedKey,
                keyDecryptionNonce: keyDecryptionNonce,
                publicKey: publicKey,
                encryptedSecretKey: encryptedSecretKey,
                secretKeyDecryptionNonce: secretKeyDecryptionNonce,
                memLimit: memLimit,
                opsLimit: opsLimit
            )
        }

        return AuthResponsePayload(
            userId: Int64(id),
            keyAttributes: keyAttrs,
            encryptedToken: encryptedToken,
            token: token,
            twoFactorSessionId: twoFactorSessionId,
            passkeySessionId: passkeySessionId,
            accountsUrl: accountsUrl
        )
    }
}
