// EnteCrypto - Cryptographic operations for Ente native apps.

import Foundation
import EnteCore
import Crypto
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

public enum CryptoError: Error, Equatable, LocalizedError {
    case invalidSalt
    case invalidParameters
    case invalidKeyLength
    case derivationFailed
    case decryptionFailed
    case singleShotDecryptionFailed
    case encryptionFailed
    case invalidNonce
    case invalidTag
    case rustBackendUnavailable
    case rustBackendError(String)
    
    public var errorDescription: String? {
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
        case .rustBackendUnavailable:
            return "Rust crypto backend is unavailable on tvOS"
        case .rustBackendError(let message):
            return "Rust crypto backend error: \(message)"
        }
    }
}

// MARK: - Main Crypto Class

public class EnteCrypto {
    private static let logger = Logger(label: "EnteCrypto")

    private static func rustBridge() throws -> RustCryptoBridge {
        guard RustCryptoBridge.isAvailable else {
            throw CryptoError.rustBackendUnavailable
        }
        return RustCryptoBridge.shared
    }
    
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

        guard let saltData = Data(base64Encoded: salt) else {
            throw CryptoError.invalidSalt
        }

        do {
            return try rustBridge().deriveArgonKey(
                password: password,
                salt: saltData,
                memLimit: memLimit,
                opsLimit: opsLimit
            )
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
    }
    
    /// Derives login key from keyEncKey - exactly matching web libsodium KDF implementation
    /// This loginKey acts as user provided password during SRP authentication
    public static func deriveLoginKey(keyEncKey: Data) throws -> Data {
        do {
            return try rustBridge().deriveLoginKey(keyEncKey: keyEncKey)
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
    }
    
    // MARK: - Key Generation
    
    /// Generates a new X25519 keypair for cast pairing
    /// Returns base64 encoded public and private keys
    public static func generateKeyPair() throws -> (publicKey: String, privateKey: String) {
        do {
            return try rustBridge().generateKeyPair()
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
    }
    
    // MARK: - Encryption/Decryption Operations
    
    /// SecretBox encryption - mirrors CLI SecretBoxOpen
    public static func secretBoxOpen(_ cipherText: Data, nonce: Data, key: Data) throws -> Data {
        guard nonce.count == 24, key.count == 32 else {
            throw CryptoError.invalidParameters
        }

        do {
            return try rustBridge().secretBoxOpen(cipherText: cipherText, nonce: nonce, key: key)
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
    }
    
    /// SealedBox decryption - standard libsodium sealed box
    public static func sealedBoxOpen(_ cipherText: Data, publicKey: Data, secretKey: Data) throws -> Data {
        guard publicKey.count == 32, secretKey.count == 32 else {
            throw CryptoError.invalidParameters
        }

        do {
            return try rustBridge().sealedBoxOpen(cipherText: cipherText, publicKey: publicKey, secretKey: secretKey)
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
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

        do {
            return try rustBridge().decryptSecretStream(encryptedData: encryptedData, key: key, header: header)
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
    }
    
    // MARK: - Cast Operations
    
    /// Generates X25519 keypair for cast pairing (using Swift CryptoKit for compatibility)
    /// Returns base64 encoded keys for network transmission
    public static func generateCastKeyPair() throws -> (publicKey: String, privateKey: String) {
        try generateKeyPair()
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
        do {
            return try rustBridge().blake2bHashHex(data)
        } catch let err as CryptoError {
            throw err
        } catch {
            throw CryptoError.rustBackendError(error.localizedDescription)
        }
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
