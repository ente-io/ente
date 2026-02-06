import Foundation
import EnteCore
import Sodium
import Crypto
import Logging
import BigInt

// MARK: - SRP Constants

public struct SRPConstants {
    public static let groupSize = 4096
    public static let hashAlgorithm = "SHA-256"
    public static let generator = "05"
    
    // RFC 5054 4096-bit safe prime
    public static let prime = "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6BF12FFA06D98A0864D87602733EC86A64521F2B18177B200CBBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5BFCE0FD108E4B82D120A92108011A723C12A787E6D788719A10BDBA5B2699C327186AF4E23C1A946834B6150BDA2583E9CA2AD44CE8DBBBC2DB04DE8EF92E8EFC141FBECAA6287C59474E6BC05D99B2964FA090C3A2233BA186515BE7ED1F612970CEE2D7AFB81BDD762170481CD0069127D5B05AA993B4EA988D8FDDC186FFB7DC90A6C08F4DF435C934063199FFFFFFFFFFFFFFFF"
}

// MARK: - SRP Client

public class SRPClient {
    private let logger = Logger(label: "SRPClient")
    private let sodium = Sodium()
    
    private let identity: Data
    private let password: Data
    private let salt: Data
    private let privateKey: BigInt
    private var serverPublicKey: Data?
    private var sharedSecret: Data?
    private var clientPublicKey: Data?
    
    // RFC 5054 parameters
    private let generator: BigInt
    private let prime: BigInt
    
    public init(identity: Data, password: Data, salt: Data) throws {
        self.identity = identity
        self.password = password
        self.salt = salt
        
        self.prime = BigInt(SRPConstants.prime, radix: 16)!
        self.generator = BigInt(SRPConstants.generator, radix: 16)!
        guard let randomBytes = sodium.randomBytes.buf(length: 32) else {
            throw CryptoError.derivationFailed
        }
        self.privateKey = BigInt(Data(randomBytes))
        
        logger.debug("SRP client initialized")
    }
    
    // MARK: - Authentication Flow
    
    /// Generate client public key A = g^a mod N
    public func generateClientCredentials() -> Data {
        let A = generator.power(privateKey, modulus: prime)
        let result = A.srpSerialize()
        self.clientPublicKey = result
        
        logger.debug("Generated client public key (\(result.count) bytes)")
        return result
    }
    
    /// Process server public key and compute shared secret
    public func processServerChallenge(serverPublicKey: Data) throws {
        self.serverPublicKey = serverPublicKey
        
        guard let clientA = clientPublicKey else {
            throw CryptoError.invalidParameters
        }
        
        logger.debug("Processing server challenge (\(serverPublicKey.count) bytes)")
        
        let B = BigInt(serverPublicKey)
        
        let uData = SHA256.hash(data: clientA + serverPublicKey)
        let u = BigInt(Data(uData))
        
        let innerHash = SHA256.hash(data: identity + ":".data(using: .utf8)! + password)
        let xData = SHA256.hash(data: salt + Data(innerHash))
        let x = BigInt(Data(xData))
        
        let kData = SHA256.hash(data: prime.srpSerialize() + generator.srpSerialize())
        let k = BigInt(Data(kData))
        
        let gx = generator.power(x, modulus: prime)
        let kgx = (k * gx) % prime
        let base = (B - kgx + prime) % prime
        let exponent = (privateKey + u * x)
        let S = base.power(exponent, modulus: prime)
        
        self.sharedSecret = S.srpSerialize()
        logger.debug("Computed shared secret (\(sharedSecret!.count) bytes)")
    }
    
    /// Generate client evidence M1
    public func generateClientEvidence() throws -> Data {
        guard let clientA = clientPublicKey,
              let serverB = serverPublicKey,
              let S = sharedSecret else {
            throw CryptoError.invalidParameters
        }
        
        let m1 = Data(SHA256.hash(data: clientA + serverB + S))
        logger.debug("Generated client evidence (\(m1.count) bytes)")
        return m1
    }
    
    /// Verify server evidence M2
    public func verifyServerEvidence(_ serverEvidence: Data) throws -> Bool {
        guard let clientA = clientPublicKey,
              let S = sharedSecret else {
            throw CryptoError.invalidParameters
        }
        
        let clientM1 = try generateClientEvidence()
        let expectedM2Data = SHA256.hash(data: clientA + clientM1 + S)
        let expectedM2 = Data(expectedM2Data)
        
        let isValid = expectedM2 == serverEvidence
        logger.debug("Server evidence verification: \(isValid)")
        return isValid
    }
    
    /// Get session key from shared secret
    public func getSessionKey() throws -> Data {
        guard let S = sharedSecret else {
            throw CryptoError.invalidParameters
        }
        
        let sessionKeyData = SHA256.hash(data: S)
        return Data(sessionKeyData)
    }
}

// MARK: - BigInt Extensions

extension BigInt {
    /// Create BigInt from byte data
    init(_ data: Data) {
        self.init(sign: .plus, magnitude: BigUInt(data))
    }
    
    /// Serialize to 512-byte padded format
    func srpSerialize() -> Data {
        let magnitude = self.magnitude
        var data = magnitude.serialize()
        
        let targetLength = 512
        if data.count < targetLength {
            let padding = Data(count: targetLength - data.count)
            data = padding + data
        }
        
        return data
    }
}