import Foundation

#if canImport(CoreUniFFI)
import CoreUniFFI
#endif

enum IOS26CoreCryptoError: Error, LocalizedError {
  case unavailable
  case operationFailed(String)

  var errorDescription: String? {
    switch self {
    case .unavailable:
      return "core UniFFI module is unavailable"
    case .operationFailed(let message):
      return message
    }
  }
}

final class IOS26CoreCryptoBridge {
  static let shared = IOS26CoreCryptoBridge()

  private init() {}

  var isAvailable: Bool {
    #if canImport(CoreUniFFI)
    true
    #else
    false
    #endif
  }

  func normalizeHashToHex(_ expectedHash: String) throws -> String {
    #if canImport(CoreUniFFI)
    do {
      return try CoreUniFFI.normalizeHashToHex(expectedHash: expectedHash)
    } catch {
      throw IOS26CoreCryptoError.operationFailed(error.localizedDescription)
    }
    #else
    throw IOS26CoreCryptoError.unavailable
    #endif
  }

  func blake2bHashBase64(_ data: Data, outLen: UInt32? = nil) throws -> String {
    #if canImport(CoreUniFFI)
    do {
      return try CoreUniFFI.blake2bHashB64(data: [UInt8](data), outLen: outLen)
    } catch {
      throw IOS26CoreCryptoError.operationFailed(error.localizedDescription)
    }
    #else
    throw IOS26CoreCryptoError.unavailable
    #endif
  }

  func verifyBlake2bHash(_ data: Data, expectedHash: String) throws -> Bool {
    #if canImport(CoreUniFFI)
    do {
      return try CoreUniFFI.verifyBlake2bHash(data: [UInt8](data), expectedHash: expectedHash)
    } catch {
      throw IOS26CoreCryptoError.operationFailed(error.localizedDescription)
    }
    #else
    throw IOS26CoreCryptoError.unavailable
    #endif
  }

  func verifyBlake2bHash(filePath: String, expectedHash: String) throws -> Bool {
    #if canImport(CoreUniFFI)
    do {
      return try CoreUniFFI.verifyBlake2bHashForFile(
        filePath: filePath,
        expectedHash: expectedHash
      )
    } catch {
      throw IOS26CoreCryptoError.operationFailed(error.localizedDescription)
    }
    #else
    throw IOS26CoreCryptoError.unavailable
    #endif
  }

  func decryptAndVerifySecretStreamPayload(
    encryptedData: Data,
    decryptionHeader: Data,
    key: Data,
    expectedHash: String
  ) throws -> Data {
    #if canImport(CoreUniFFI)
    do {
      let decrypted = try CoreUniFFI.decryptAndVerifySecretStreamPayload(
        encryptedData: [UInt8](encryptedData),
        decryptionHeader: [UInt8](decryptionHeader),
        key: [UInt8](key),
        expectedHash: expectedHash
      )
      return Data(decrypted)
    } catch {
      throw IOS26CoreCryptoError.operationFailed(error.localizedDescription)
    }
    #else
    throw IOS26CoreCryptoError.unavailable
    #endif
  }
}
