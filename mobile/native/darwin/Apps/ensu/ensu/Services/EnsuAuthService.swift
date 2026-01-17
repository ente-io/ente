import Foundation
import EnteCore
import EnteNetwork

struct SrpLoginResult {
    let twoFactorSessionId: String?
    let passkeySessionId: String?
    let accountsUrl: String?

    var requiresTwoFactor: Bool { twoFactorSessionId?.isEmpty == false }
    var requiresPasskey: Bool { passkeySessionId?.isEmpty == false }
}

struct AuthResponsePayload: Hashable {
    let userId: Int64
    let keyAttributes: KeyAttributes?
    let encryptedToken: String?
    let token: String?
    let twoFactorSessionId: String?
    let passkeySessionId: String?
    let accountsUrl: String?

    var requiresTwoFactor: Bool { twoFactorSessionId?.isEmpty == false }
    var requiresPasskey: Bool { passkeySessionId?.isEmpty == false }
}

final class EnsuAuthService {
    static let shared = EnsuAuthService()

    private let tokenProvider = EnsuAuthTokenProvider()

    private var networkFactory: NetworkFactory

    private var accountsUrlFallback: String {
        networkFactory.configuration.accountsEndpoint?.absoluteString ?? "https://accounts.ente.io"
    }

    private init() {
        networkFactory = NetworkFactory(
            configuration: EnsuDeveloperSettings.networkConfiguration,
            app: .ensu,
            authTokenProvider: tokenProvider
        )

        // Initialise Rust crypto backend once (no-op for pure Rust, but keeps parity).
        // Ignore errors here and surface them when actually used.
        try? initCrypto()
    }

    // MARK: - Network

    func updateEndpoint(_ endpoint: URL?) {
        EnsuDeveloperSettings.setEndpoint(endpoint)
        networkFactory = NetworkFactory(
            configuration: EnsuDeveloperSettings.networkConfiguration,
            app: .ensu,
            authTokenProvider: tokenProvider
        )
    }

    func getSrpAttributes(email: String) async throws -> SrpAttributes {
        let attrs = try await networkFactory.authentication.getSRPAttributes(email: email)
        return SrpAttributes(
            srpUserId: attrs.srpUserID,
            srpSalt: attrs.srpSalt,
            kekSalt: attrs.kekSalt,
            memLimit: UInt32(attrs.memLimit),
            opsLimit: UInt32(attrs.opsLimit),
            isEmailMfaEnabled: attrs.isEmailMFAEnabled
        )
    }

    func sendOtp(email: String) async throws {
        try await networkFactory.authentication.sendLoginOTP(email: email)
    }

    func verifyOtp(email: String, otp: String) async throws -> AuthResponsePayload {
        let response = try await networkFactory.authentication.verifyEmail(email: email, otp: otp)
        return AuthResponsePayload(from: response)
    }

    func verifyTwoFactor(sessionId: String, code: String) async throws -> AuthResponsePayload {
        let response = try await networkFactory.authentication.verifyTOTP(sessionID: sessionId, otp: code)
        return AuthResponsePayload(from: response)
    }

    func getTokenForPasskeySession(sessionId: String) async throws -> AuthResponsePayload {
        do {
            let response = try await networkFactory.authentication.getTokenForPasskeySession(sessionID: sessionId)
            return AuthResponsePayload(from: response)
        } catch let error as EnteError {
            // Mirror Flutter behavior:
            // - 400 => not verified
            // - 404/410 => expired
            if case let .serverError(code, _) = error {
                if code == 400 { throw PasskeySessionNotVerifiedError() }
                if code == 404 || code == 410 { throw PasskeySessionExpiredError() }
            }
            throw error
        }
    }

    // MARK: - SRP Login

    func loginWithSrp(email: String, password: String, srpAttributes: SrpAttributes) async throws -> SrpLoginResult {
        defer { srpClear() }

        // 1) Start SRP (heavy crypto)
        let start = try await Task.detached(priority: .userInitiated) {
            try srpStart(password: password, srpAttrs: srpAttributes)
        }.value

        // 2) Create SRP session
        let session = try await networkFactory.authentication.createSRPSession(
            srpUserID: srpAttributes.srpUserId,
            clientPub: start.srpA
        )

        // 3) Finish SRP
        let verify = try await Task.detached(priority: .userInitiated) {
            try srpFinish(srpB: session.srpB)
        }.value

        // 4) Verify SRP session
        let authResponse = try await networkFactory.authentication.verifySRPSession(
            srpUserID: srpAttributes.srpUserId,
            sessionID: session.sessionID,
            clientM1: verify.srpM1
        )

        // If additional auth factors are required, return the session IDs.
        let passkeySessionId = (authResponse.passkeySessionID?.isEmpty == false) ? authResponse.passkeySessionID : nil
        let twoFactorSessionId = (authResponse.effectiveTwoFactorSessionID?.isEmpty == false) ? authResponse.effectiveTwoFactorSessionID : nil
        if passkeySessionId != nil || twoFactorSessionId != nil {
            return SrpLoginResult(
                twoFactorSessionId: twoFactorSessionId,
                passkeySessionId: passkeySessionId,
                accountsUrl: (authResponse.accountsUrl?.isEmpty == false) ? authResponse.accountsUrl : accountsUrlFallback
            )
        }

        // 5) Decrypt secrets using the KEK derived in srpStart
        guard let keyAttrsNet = authResponse.keyAttributes else {
            throw EnteError.invalidResponse
        }

        let keyAttrs = KeyAttributes(
            kekSalt: keyAttrsNet.kekSalt,
            encryptedKey: keyAttrsNet.encryptedKey,
            keyDecryptionNonce: keyAttrsNet.keyDecryptionNonce,
            publicKey: keyAttrsNet.publicKey,
            encryptedSecretKey: keyAttrsNet.encryptedSecretKey,
            secretKeyDecryptionNonce: keyAttrsNet.secretKeyDecryptionNonce,
            memLimit: UInt32(keyAttrsNet.memLimit),
            opsLimit: UInt32(keyAttrsNet.opsLimit)
        )

        let secrets = try await Task.detached(priority: .userInitiated) {
            try srpDecryptSecrets(
                keyAttrs: keyAttrs,
                encryptedToken: authResponse.encryptedToken,
                plainToken: authResponse.token
            )
        }.value

        try storeSecrets(
            email: email,
            userId: authResponse.id.rawValue,
            secrets: secrets
        )

        return SrpLoginResult(twoFactorSessionId: nil, passkeySessionId: nil, accountsUrl: nil)
    }

    // MARK: - Continuation (email MFA / 2FA / passkeys)

    func loginAfterChallenge(
        email: String,
        password: String,
        srpAttributes: SrpAttributes,
        userId: Int64,
        keyAttributes: KeyAttributes,
        encryptedToken: String?,
        token: String?
    ) async throws {
        let kek = try await Task.detached(priority: .userInitiated) {
            try deriveKekForLogin(
                password: password,
                kekSalt: srpAttributes.kekSalt,
                memLimit: srpAttributes.memLimit,
                opsLimit: srpAttributes.opsLimit
            )
        }.value

        let secrets = try await Task.detached(priority: .userInitiated) {
            try decryptSecretsWithKek(
                kek: kek,
                keyAttrs: keyAttributes,
                encryptedToken: encryptedToken,
                plainToken: token
            )
        }.value

        try storeSecrets(email: email, userId: userId, secrets: secrets)
    }

    // MARK: - Storage

    private func storeSecrets(email: String, userId: Int64, secrets: AuthSecrets) throws {
        let masterKey = Data(secrets.masterKey)
        let secretKey = Data(secrets.secretKey)
        let token = Data(secrets.token).base64URLEncodedString()

        try CredentialStore.shared.save(
            email: email,
            userId: userId,
            masterKey: masterKey,
            secretKey: secretKey,
            token: token
        )
    }
}

// MARK: - Response mapping

private extension AuthResponsePayload {
    init(from response: AuthorizationResponse) {
        let keyAttrs: KeyAttributes? = response.keyAttributes.map {
            KeyAttributes(
                kekSalt: $0.kekSalt,
                encryptedKey: $0.encryptedKey,
                keyDecryptionNonce: $0.keyDecryptionNonce,
                publicKey: $0.publicKey,
                encryptedSecretKey: $0.encryptedSecretKey,
                secretKeyDecryptionNonce: $0.secretKeyDecryptionNonce,
                memLimit: UInt32($0.memLimit),
                opsLimit: UInt32($0.opsLimit)
            )
        }

        self.init(
            userId: response.id.rawValue,
            keyAttributes: keyAttrs,
            encryptedToken: response.encryptedToken,
            token: response.token,
            twoFactorSessionId: response.effectiveTwoFactorSessionID,
            passkeySessionId: response.passkeySessionID,
            accountsUrl: response.accountsUrl
        )
    }
}

// MARK: - Passkey errors

struct PasskeySessionNotVerifiedError: Error {}
struct PasskeySessionExpiredError: Error {}
