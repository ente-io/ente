import Foundation
import EnteCore
import Logging

// MARK: - Authentication Models

public struct SRPAttributes: Codable {
    public let srpUserID: String
    public let srpSalt: String
    public let kekSalt: String
    public let memLimit: Int
    public let opsLimit: Int
    public let isEmailMFAEnabled: Bool
    
    public init(srpUserID: String, srpSalt: String, kekSalt: String, memLimit: Int, opsLimit: Int, isEmailMFAEnabled: Bool) {
        self.srpUserID = srpUserID
        self.srpSalt = srpSalt
        self.kekSalt = kekSalt
        self.memLimit = memLimit
        self.opsLimit = opsLimit
        self.isEmailMFAEnabled = isEmailMFAEnabled
    }
}

public struct CreateSRPSessionResponse: Codable {
    public let sessionID: String
    public let srpB: String
    
    public init(sessionID: String, srpB: String) {
        self.sessionID = sessionID
        self.srpB = srpB
    }
}

public struct KeyAttributes: Codable {
    public let kekSalt: String
    public let encryptedKey: String
    public let keyDecryptionNonce: String
    public let publicKey: String
    public let encryptedSecretKey: String
    public let secretKeyDecryptionNonce: String
    public let memLimit: Int
    public let opsLimit: Int
    
    public init(kekSalt: String, encryptedKey: String, keyDecryptionNonce: String, publicKey: String, encryptedSecretKey: String, secretKeyDecryptionNonce: String, memLimit: Int, opsLimit: Int) {
        self.kekSalt = kekSalt
        self.encryptedKey = encryptedKey
        self.keyDecryptionNonce = keyDecryptionNonce
        self.publicKey = publicKey
        self.encryptedSecretKey = encryptedSecretKey
        self.secretKeyDecryptionNonce = secretKeyDecryptionNonce
        self.memLimit = memLimit
        self.opsLimit = opsLimit
    }
}

public struct AuthorizationResponse: Codable {
    public let keyAttributes: KeyAttributes?
    public let encryptedToken: String?
    public let token: String?
    public let twoFactorSessionID: String?
    public let twoFactorSessionIDV2: String?
    public let passkeySessionID: String?
    public let accountsUrl: String?
    public let id: UserID
    
    public init(keyAttributes: KeyAttributes?, encryptedToken: String?, token: String?, twoFactorSessionID: String?, twoFactorSessionIDV2: String?, passkeySessionID: String?, accountsUrl: String?, id: UserID) {
        self.keyAttributes = keyAttributes
        self.encryptedToken = encryptedToken
        self.token = token
        self.twoFactorSessionID = twoFactorSessionID
        self.twoFactorSessionIDV2 = twoFactorSessionIDV2
        self.passkeySessionID = passkeySessionID
        self.accountsUrl = accountsUrl
        self.id = id
    }
    
    public var effectiveTwoFactorSessionID: String? {
        return twoFactorSessionIDV2 ?? twoFactorSessionID
    }
    
    public var isMFARequired: Bool {
        return effectiveTwoFactorSessionID?.isEmpty == false
    }
    
    public var isPasskeyRequired: Bool {
        return passkeySessionID?.isEmpty == false
    }
}

// MARK: - Authentication Gateway

public class AuthenticationGateway {
    private let client: APIClient
    private let logger = Logger(label: "AuthenticationGateway")
    
    internal init(client: APIClient) {
        self.client = client
    }
    
    // MARK: - SRP Authentication
    
    public func getSRPAttributes(email: String) async throws -> SRPAttributes {
        logger.info("Getting SRP attributes for email")
        
        struct Response: Codable {
            let attributes: SRPAttributes
        }
        
        let response = try await client.request(
            AuthEndpoint.getSRPAttributes(email: email),
            responseType: Response.self
        )
        
        return response.attributes
    }
    
    public func createSRPSession(srpUserID: String, clientPub: String) async throws -> CreateSRPSessionResponse {
        logger.info("Creating SRP session")
        
        return try await client.request(
            AuthEndpoint.createSRPSession(srpUserID: srpUserID, clientPub: clientPub),
            responseType: CreateSRPSessionResponse.self
        )
    }
    
    public func verifySRPSession(srpUserID: String, sessionID: String, clientM1: String) async throws -> AuthorizationResponse {
        logger.info("Verifying SRP session")
        
        return try await client.request(
            AuthEndpoint.verifySRPSession(srpUserID: srpUserID, sessionID: sessionID, clientM1: clientM1),
            responseType: AuthorizationResponse.self
        )
    }
    
    // MARK: - Email OTP
    
    public func sendLoginOTP(email: String, purpose: String = "login") async throws {
        logger.info("Sending login OTP")
        
        try await client.request(AuthEndpoint.sendLoginOTP(email: email, purpose: purpose))
    }
    
    public func verifyEmail(email: String, otp: String) async throws -> AuthorizationResponse {
        logger.info("Verifying email with OTP")
        
        return try await client.request(
            AuthEndpoint.verifyEmail(email: email, otp: otp),
            responseType: AuthorizationResponse.self
        )
    }
    
    // MARK: - Two-Factor Authentication
    
    public func verifyTOTP(sessionID: String, otp: String) async throws -> AuthorizationResponse {
        logger.info("Verifying TOTP")
        
        return try await client.request(
            AuthEndpoint.verifyTOTP(sessionID: sessionID, otp: otp),
            responseType: AuthorizationResponse.self
        )
    }
    
    // MARK: - Passkeys
    
    public func getTokenForPasskeySession(sessionID: String) async throws -> AuthorizationResponse {
        logger.info("Getting token for passkey session")
        
        return try await client.request(
            AuthEndpoint.getTokenForPasskeySession(sessionID: sessionID),
            responseType: AuthorizationResponse.self
        )
    }
}