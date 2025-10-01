// EnteCrypto - Cryptographic operations for Ente native apps
// Based on CLI implementation with libsodium

import Foundation
import EnteCore
import Crypto
import CryptoKit
import Sodium
import Logging

// MARK: - Constants (mirrors CLI crypto.go)

public struct CryptoConstants {
    // Login key derivation constants - matches CLI crypto.go exactly
    public static let loginSubKeyLength: UInt32 = 32  // CLI: loginSubKeyLen = 32
    public static let loginSubKeyId: UInt64 = 1       // CLI: loginSubKeyId = 1
    public static let loginSubKeyContext = "loginctx" // CLI: loginSubKeyContext = "loginctx"
    
    // BLAKE2b constants

    public static let cryptoKDFBlake2bBytesMax: UInt32 = 64
    public static let cryptoGenerichashBlake2bSaltBytes = 16
    public static let cryptoGenerichashBlake2bPersonalBytes = 16
    
    // Box constants
    public static let boxSealBytes = 48 // 32 for ephemeral public key + 16 for MAC
    
    // Default key lengths
    public static let keyEncryptionKeyLength = 32
    public static let argonSaltLength = 16
}

// MARK: - Crypto Errors

public enum CryptoError: Error, Equatable {
    case invalidSalt
    case invalidParameters
    case invalidKeyLength
    case derivationFailed
    case decryptionFailed
    case singleShotDecryptionFailed
    case encryptionFailed
    case invalidNonce
    case invalidTag
    
    public var localizedDescription: String {
        switch self {
        case .invalidSalt:
            return "Invalid salt format"
        case .invalidParameters:
            return "Invalid cryptographic parameters"
        case .invalidKeyLength:
            return "Invalid key length"
        case .derivationFailed:
            return "Key derivation failed"
        case .singleShotDecryptionFailed:
            return "Single shot decryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .encryptionFailed:
            return "Encryption failed"
        case .invalidNonce:
            return "Invalid nonce"
        case .invalidTag:
            return "Invalid authentication tag"
        }
    }
}

// MARK: - Main Crypto Class

public class EnteCrypto {
    private static let logger = Logger(label: "EnteCrypto")
    
    // MARK: - Key Derivation
    
    /// Derives a key using Argon2id - mirrors CLI DeriveArgonKey
    public static func deriveArgonKey(
        password: String,
        salt: String,
        memLimit: Int,
        opsLimit: Int
    ) throws -> Data {
        logger.debug("Deriving Argon key with memLimit: \(memLimit), opsLimit: \(opsLimit)")
        
        guard memLimit >= 1024 && opsLimit >= 1 else {
            throw CryptoError.invalidParameters
        }
        
        // Decode salt from base64
        guard let saltData = Data(base64Encoded: salt) else {
            throw CryptoError.invalidSalt
        }
        
        let passwordData = password.data(using: .utf8)!
        
        // ✅ SOLUTION FOUND: Swift Sodium expects memLimit in bytes and produces 
        // the same result as Go when we pass the original byte value directly!
        // Go: argon2.IDKey(..., uint32(memLimit/1024), ...) uses KB internally
        // Swift: sodium.pwHash.hash(..., memLimit: memLimit, ...) uses bytes directly
        // Both produce the same final keyEncKey result!
        
        logger.debug("Using Argon2id with memLimit=\(memLimit) bytes, opsLimit=\(opsLimit)")
        
        let sodium = Sodium()
        guard let derivedKey = sodium.pwHash.hash(
            outputLength: CryptoConstants.keyEncryptionKeyLength,
            passwd: passwordData.bytes,
            salt: saltData.bytes,
            opsLimit: opsLimit,
            memLimit: memLimit,  // Use original bytes value - produces same result as Go!
            alg: .Argon2ID13
        ) else {
            throw CryptoError.derivationFailed
        }
        
        let result = Data(derivedKey)
        logger.debug("Derived keyEncKey successfully")
        return result
    }
    
    /// Derives login key from keyEncKey - exactly matching web libsodium KDF implementation
    /// This loginKey acts as user provided password during SRP authentication
    public static func deriveLoginKey(keyEncKey: Data) throws -> Data {
        logger.debug("Deriving login key using libsodium KDF (matching web implementation)")
        
        // Use the exact same libsodium KDF as web implementation:
        // deriveSubKeyBytes(kek, 32, 1, "loginctx") and take first 16 bytes
        // Web: sodium.crypto_kdf_derive_from_key(32, 1, "loginctx", kek)
        let sodium = Sodium()
        
        guard let derivedKey = sodium.keyDerivation.derive(
            secretKey: keyEncKey.bytes,
            index: CryptoConstants.loginSubKeyId,      // 1
            length: Int(CryptoConstants.loginSubKeyLength), // 32
            context: CryptoConstants.loginSubKeyContext     // "loginctx"
        ) else {
            throw CryptoError.derivationFailed
        }
        
        logger.debug("Libsodium KDF derived key (32 bytes)")
        
        // Return the first 16 bytes (same as web: kekSubKeyBytes.slice(0, 16))
        let result = Data(derivedKey.prefix(16))
        logger.debug("Login key derived (16 bytes)")
        return result
    }
    
    // MARK: - Key Generation
    
    /// Generates a new X25519 keypair for cast pairing
    /// Returns base64 encoded public and private keys
    public static func generateKeyPair() -> (publicKey: String, privateKey: String) {
        logger.debug("Generating X25519 keypair for cast pairing")
        
        let sodium = Sodium()
        let keyPair = sodium.box.keyPair()!
        
        let publicKeyB64 = Data(keyPair.publicKey).base64EncodedString()
        let privateKeyB64 = Data(keyPair.secretKey).base64EncodedString()
        
        logger.debug("Generated keypair - public: \(publicKeyB64.prefix(16))...")
        
        return (publicKey: publicKeyB64, privateKey: privateKeyB64)
    }
    
    /// SealedBox encryption for sending data to cast receiver
    public static func sealedBoxSeal(_ plainText: Data, recipientPublicKey: Data) throws -> Data {
        guard recipientPublicKey.count == 32 else {
            throw CryptoError.invalidParameters
        }
        
        let sodium = Sodium()
        guard let encrypted = sodium.box.seal(
            message: plainText.bytes,
            recipientPublicKey: recipientPublicKey.bytes
        ) else {
            throw CryptoError.encryptionFailed
        }
        
        return Data(encrypted)
    }
    
    // MARK: - Encryption/Decryption Operations
    
    /// SecretBox encryption - mirrors CLI SecretBoxOpen
    public static func secretBoxOpen(_ cipherText: Data, nonce: Data, key: Data) throws -> Data {
        guard nonce.count == 24, key.count == 32 else {
            throw CryptoError.invalidParameters
        }
        
        let sodium = Sodium()
        guard let decrypted = sodium.secretBox.open(
            authenticatedCipherText: cipherText.bytes,
            secretKey: key.bytes,
            nonce: nonce.bytes
        ) else {
            throw CryptoError.decryptionFailed
        }
        
        return Data(decrypted)
    }
    
    /// SealedBox decryption - standard libsodium sealed box
    public static func sealedBoxOpen(_ cipherText: Data, publicKey: Data, secretKey: Data) throws -> Data {
        guard publicKey.count == 32, secretKey.count == 32 else {
            throw CryptoError.invalidParameters
        }
        
        let sodium = Sodium()
        guard let decrypted = sodium.box.open(
            anonymousCipherText: cipherText.bytes,
            recipientPublicKey: publicKey.bytes,
            recipientSecretKey: secretKey.bytes
        ) else {
            throw CryptoError.decryptionFailed
        }
        
        return Data(decrypted)
    }
    
    /// ChaCha20-Poly1305 encryption - standard libsodium AEAD
    public static func encryptChaCha20Poly1305(data: Data, key: Data) throws -> (cipherText: Data, nonce: Data) {
        guard key.count == 32 else {
            throw CryptoError.invalidKeyLength
        }
        
        let sodium = Sodium()
        
        // Generate nonce automatically and return both ciphertext and nonce
        guard let result: (authenticatedCipherText: [UInt8], nonce: [UInt8]) = sodium.aead.xchacha20poly1305ietf.encrypt(
            message: data.bytes,
            secretKey: key.bytes
        ) else {
            throw CryptoError.encryptionFailed
        }
        
        return (Data(result.authenticatedCipherText), Data(result.nonce))
    }
    
    /// ChaCha20-Poly1305 decryption - standard libsodium AEAD
    public static func decryptChaCha20Poly1305(cipherText: Data, key: Data, nonce: Data) throws -> Data {
        guard key.count == 32 else {
            throw CryptoError.invalidKeyLength
        }
        
        let sodium = Sodium()
        
        guard let plainText = sodium.aead.xchacha20poly1305ietf.decrypt(
            authenticatedCipherText: cipherText.bytes,
            secretKey: key.bytes,
            nonce: nonce.bytes
        ) else {
            throw CryptoError.decryptionFailed
        }
        
        return Data(plainText)
    }
    
    // MARK: - Stream Decryption (XChaCha20-Poly1305)
    
    /// Stream decryption using XChaCha20Poly1305 secretstream
    /// This is the main method used for file content and metadata decryption in Ente
    public static func decryptSecretStream(encryptedData: Data, key: Data, header: Data) throws -> Data {
        guard key.count == 32 else {
            throw CryptoError.invalidKeyLength
        }
        guard header.count == 24 else {
            throw CryptoError.invalidParameters
        }
        
    let sodium = Sodium()
    let overhead = 17 // crypto_secretstream_xchacha20poly1305_ABYTES (libsodium per-chunk overhead)
        let plaintextChunkSize = 4 * 1024 * 1024 // Matches Dart encryptionChunkSize
        let cipherChunkSize = plaintextChunkSize + overhead
        
        guard let pull = sodium.secretStream.xchacha20poly1305.initPull(
            secretKey: key.bytes,
            header: header.bytes
        ) else {
            throw CryptoError.singleShotDecryptionFailed
        }
        
        var offset = 0
        var chunkIndex = 0
        var output = Data()
        let total = encryptedData.count
        
        while offset < total {
            let remaining = total - offset
            let take = remaining <= cipherChunkSize ? remaining : cipherChunkSize
            let range = offset..<(offset + take)
            let ct = encryptedData.subdata(in: range)
            guard let (msg, tag) = pull.pull(cipherText: ct.bytes) else {
                throw CryptoError.decryptionFailed
            }
            output.append(Data(msg))
            offset += take
            chunkIndex += 1
            if tag == .FINAL {
                if offset != total {
                    throw CryptoError.decryptionFailed
                }
                return output
            }
        }
        throw CryptoError.decryptionFailed
    }
    
    // MARK: - Cast Operations
    
    /// Generates X25519 keypair for cast pairing (using Swift CryptoKit for compatibility)
    /// Returns base64 encoded keys for network transmission
    public static func generateCastKeyPair() -> (publicKey: String, privateKey: String) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        let publicKeyB64 = publicKey.rawRepresentation.base64EncodedString()
        let privateKeyB64 = privateKey.rawRepresentation.base64EncodedString()
        
        return (publicKey: publicKeyB64, privateKey: privateKeyB64)
    }
    
    /// Decrypts cast payload using sealed box (anonymous encryption)
    /// Used to decrypt collection info sent from mobile client
    public static func decryptCastPayload(
        encryptedPayload: String,
        recipientPublicKey: String,
        recipientPrivateKey: String
    ) throws -> Data {
        guard let cipherText = Data(base64Encoded: encryptedPayload),
              let publicKey = Data(base64Encoded: recipientPublicKey),
              let privateKey = Data(base64Encoded: recipientPrivateKey) else {
            throw CryptoError.invalidParameters
        }
        
        return try sealedBoxOpen(cipherText, publicKey: publicKey, secretKey: privateKey)
    }
    
    // MARK: - Hash Operations
    
    /// Computes BLAKE2b hash using libsodium genericHash (64-byte output)
    /// This matches the hash format used across all Ente platforms
    public static func computeBlake2bHash(_ data: Data) throws -> String {
        let sodium = Sodium()
        
        guard let hashBytes = sodium.genericHash.hash(message: data.bytes, outputLength: 64) else {
            throw CryptoError.derivationFailed
        }
        
        return hashBytes.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Verifies file content hash with dual format support
    /// Server stores hashes as base64, we compute as hex - handles both formats
    public static func verifyFileHash(data: Data, expectedHash: String?) -> Bool {
        guard let expectedHash = expectedHash, !expectedHash.isEmpty else {
            // No hash available - allow for backwards compatibility
            return true
        }
        
        guard let computedHash = try? computeBlake2bHash(data) else {
            return false
        }
        
        // Try direct hex comparison first
        if computedHash.lowercased() == expectedHash.lowercased() {
            return true
        }
        
        // Try base64 to hex conversion
        if let base64DecodedHash = Data(base64Encoded: expectedHash) {
            let expectedHashAsHex = base64DecodedHash.map { String(format: "%02x", $0) }.joined()
            if computedHash.lowercased() == expectedHashAsHex.lowercased() {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Data Extension for Bytes

extension Data {
    var bytes: [UInt8] {
        return Array(self)
    }
}
