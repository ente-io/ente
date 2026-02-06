import XCTest
@testable import EnteCrypto
@testable import EnteCore
@testable import EnteNetwork
import Foundation

final class EnteCryptoTests: XCTestCase {
    
    // MARK: - Key Derivation Tests
    
    func testArgonKeyDerivation() throws {
        let password = "testpassword123"
        let salt = Data(count: 16).base64EncodedString()
        let memLimit = 64 * 1024 * 1024
        let opsLimit = 3
        
        let derivedKey = try EnteCrypto.deriveArgonKey(
            password: password,
            salt: salt,
            memLimit: memLimit,
            opsLimit: opsLimit
        )
        
        XCTAssertEqual(derivedKey.count, 32)
        XCTAssertFalse(derivedKey.allSatisfy { $0 == 0 })
    }
    
    func testLoginKeyDerivation() throws {
        let keyEncKey = Data(repeating: 1, count: 32)
        let loginKey = try EnteCrypto.deriveLoginKey(keyEncKey: keyEncKey)
        
        XCTAssertEqual(loginKey.count, 16)
        XCTAssertFalse(loginKey.allSatisfy { $0 == 0 })
    }
    
    // MARK: - Encryption Tests
    
    func testSecretBoxOperations() throws {
        let message = "Hello, World!".data(using: .utf8)!
        let key = Data(repeating: 1, count: 32)
        let nonce = Data(repeating: 2, count: 24)
        
        XCTAssertThrowsError(try EnteCrypto.secretBoxOpen(message, nonce: nonce, key: key)) { error in
            XCTAssertTrue(error is CryptoError)
        }
    }
    
    func testChaCha20Poly1305Operations() throws {
        let message = "Hello, World!".data(using: .utf8)!
        let key = Data(repeating: 1, count: 32)
        
        let (cipherText, nonce) = try EnteCrypto.encryptChaCha20Poly1305(data: message, key: key)
        
        XCTAssertFalse(cipherText.isEmpty)
        XCTAssertEqual(nonce.count, 24)
        XCTAssertNotEqual(cipherText, message)
        
        let decrypted = try EnteCrypto.decryptChaCha20Poly1305(cipherText: cipherText, key: key, nonce: nonce)
        XCTAssertEqual(decrypted, message)
    }
    
    // MARK: - SRP Tests
    
    func testSRPConstants() {
        XCTAssertEqual(SRPConstants.groupSize, 4096)
        XCTAssertEqual(SRPConstants.hashAlgorithm, "SHA-256")
        XCTAssertEqual(SRPConstants.generator, "05")
        XCTAssertFalse(SRPConstants.prime.isEmpty)
    }
    
    func testSRPClientInitialization() throws {
        let identity = "user@example.com".data(using: .utf8)!
        let password = "password123".data(using: .utf8)!
        let salt = Data(repeating: 3, count: 16)
        
        let srpClient = try SRPClient(identity: identity, password: password, salt: salt)
        let clientPublicKey = srpClient.generateClientCredentials()
        
        XCTAssertFalse(clientPublicKey.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    func testLoginFlowIntegration() throws {
        let email = "test@example.com"
        let password = "testpassword"
        let salt = Data(count: 16).base64EncodedString()
        let memLimit = 64 * 1024 * 1024
        let opsLimit = 3
        
        let keyEncKey = try EnteCrypto.deriveArgonKey(
            password: password,
            salt: salt,
            memLimit: memLimit,
            opsLimit: opsLimit
        )
        XCTAssertEqual(keyEncKey.count, 32)
        
        let loginKey = try EnteCrypto.deriveLoginKey(keyEncKey: keyEncKey)
        XCTAssertEqual(loginKey.count, 16)
        
        let identity = email.data(using: .utf8)!
        let srpSalt = Data(repeating: 4, count: 16)
        let srpClient = try SRPClient(identity: identity, password: loginKey, salt: srpSalt)
        
        let clientPublicKey = srpClient.generateClientCredentials()
        XCTAssertFalse(clientPublicKey.isEmpty)
    }
    
    // func testRealServerLoginFlow() async throws {
    //     let email = "<>"
    //     let password = "<>"
    //     let baseURL = URL(string: "http://localhost:8080")!
        
    //     let config = NetworkConfiguration.selfHosted(baseURL: baseURL)
    //     let httpClient = HTTPClient()
    //     let apiClient = APIClient(
    //         configuration: config,
    //         app: .cast,
    //         authTokenProvider: nil,
    //         httpClient: httpClient
    //     )
    //     let authGateway = AuthenticationGateway(client: apiClient)
        
    //     do {
    //         let srpAttributes = try await authGateway.getSRPAttributes(email: email)
            
    //         let keyEncKey = try EnteCrypto.deriveArgonKey(
    //             password: password,
    //             salt: srpAttributes.kekSalt,
    //             memLimit: srpAttributes.memLimit,
    //             opsLimit: srpAttributes.opsLimit
    //         )
    //         let loginKey = try EnteCrypto.deriveLoginKey(keyEncKey: keyEncKey)
            
    //         let identity = srpAttributes.srpUserID.data(using: String.Encoding.utf8)!
    //         let srpSalt = Data(base64Encoded: srpAttributes.srpSalt)!
    //         let srpClient = try SRPClient(identity: identity, password: loginKey, salt: srpSalt)
            
    //         let clientPublicKey = srpClient.generateClientCredentials()
    //         let srpSession = try await authGateway.createSRPSession(
    //             srpUserID: srpAttributes.srpUserID,
    //             clientPub: clientPublicKey.base64EncodedString()
    //         )
            
    //         let serverPublicKey = Data(base64Encoded: srpSession.srpB)!
    //         try srpClient.processServerChallenge(serverPublicKey: serverPublicKey)
            
    //         let clientEvidence = try srpClient.generateClientEvidence()
    //         _ = try await authGateway.verifySRPSession(
    //             srpUserID: srpAttributes.srpUserID,
    //             sessionID: srpSession.sessionID,
    //             clientM1: clientEvidence.base64EncodedString()
    //         )
            
    //     } catch {
    //         XCTFail("Login flow failed with error: \(error)")
    //     }
    // }
}
