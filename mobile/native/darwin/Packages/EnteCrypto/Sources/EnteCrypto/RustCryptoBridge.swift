import Foundation

enum RustCryptoBridgeError: Error, LocalizedError {
    case operationFailed(String)
    case invalidOutput(String)

    var errorDescription: String? {
        switch self {
        case .operationFailed(let message):
            return message
        case .invalidOutput(let message):
            return message
        }
    }
}

@_silgen_name("ente_tvos_crypto_string_free")
private func rustStringFree(_ ptr: UnsafeMutablePointer<CChar>?)

@_silgen_name("ente_tvos_crypto_generate_keypair_b64")
private func rustGenerateKeyPair(
    _ outPublicKeyB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outPrivateKeyB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_tvos_crypto_derive_argon_key_b64")
private func rustDeriveArgonKey(
    _ passwordUtf8: UnsafePointer<CChar>?,
    _ saltB64: UnsafePointer<CChar>?,
    _ memLimit: UInt32,
    _ opsLimit: UInt32,
    _ outKeyB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_tvos_crypto_derive_login_key_b64")
private func rustDeriveLoginKey(
    _ keyEncKeyB64: UnsafePointer<CChar>?,
    _ outLoginKeyB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_tvos_crypto_secretbox_open_b64")
private func rustSecretBoxOpen(
    _ cipherTextB64: UnsafePointer<CChar>?,
    _ nonceB64: UnsafePointer<CChar>?,
    _ keyB64: UnsafePointer<CChar>?,
    _ outPlainTextB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_tvos_crypto_sealed_box_open_b64")
private func rustSealedBoxOpen(
    _ cipherTextB64: UnsafePointer<CChar>?,
    _ publicKeyB64: UnsafePointer<CChar>?,
    _ secretKeyB64: UnsafePointer<CChar>?,
    _ outPlainTextB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_tvos_crypto_secretstream_decrypt_b64")
private func rustDecryptSecretStream(
    _ encryptedDataB64: UnsafePointer<CChar>?,
    _ headerB64: UnsafePointer<CChar>?,
    _ keyB64: UnsafePointer<CChar>?,
    _ outPlainTextB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_tvos_crypto_blake2b_hash_hex")
private func rustBlake2bHashHex(
    _ dataPtr: UnsafePointer<UInt8>?,
    _ dataLen: Int,
    _ outHashHex: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

final class RustCryptoBridge {
    static let shared = RustCryptoBridge()

    static var isAvailable: Bool {
        true
    }

    private init() {}

    func generateKeyPair() throws -> (publicKey: String, privateKey: String) {
        let (publicKeyB64, privateKeyB64) = try callForTwoStringOutputs { out1, out2, outError in
            rustGenerateKeyPair(out1, out2, outError)
        }
        return (publicKeyB64, privateKeyB64)
    }

    func deriveArgonKey(password: String, salt: Data, memLimit: Int, opsLimit: Int) throws -> Data {
        let saltB64 = salt.base64EncodedString()
        let keyB64 = try withCStrings([password, saltB64]) { ptrs in
            try callForStringOutput { out, outError in
                rustDeriveArgonKey(
                    ptrs[0],
                    ptrs[1],
                    UInt32(memLimit),
                    UInt32(opsLimit),
                    out,
                    outError
                )
            }
        }

        guard let key = Data(base64Encoded: keyB64) else {
            throw RustCryptoBridgeError.invalidOutput("Failed to decode derived key")
        }
        return key
    }

    func deriveLoginKey(keyEncKey: Data) throws -> Data {
        let keyB64 = keyEncKey.base64EncodedString()
        let loginKeyB64 = try withCStrings([keyB64]) { ptrs in
            try callForStringOutput { out, outError in
                rustDeriveLoginKey(ptrs[0], out, outError)
            }
        }

        guard let key = Data(base64Encoded: loginKeyB64) else {
            throw RustCryptoBridgeError.invalidOutput("Failed to decode login key")
        }
        return key
    }

    func secretBoxOpen(cipherText: Data, nonce: Data, key: Data) throws -> Data {
        let plainTextB64 = try withCStrings([
            cipherText.base64EncodedString(),
            nonce.base64EncodedString(),
            key.base64EncodedString(),
        ]) { ptrs in
            try callForStringOutput { out, outError in
                rustSecretBoxOpen(ptrs[0], ptrs[1], ptrs[2], out, outError)
            }
        }

        guard let plainText = Data(base64Encoded: plainTextB64) else {
            throw RustCryptoBridgeError.invalidOutput("Failed to decode decrypted SecretBox payload")
        }
        return plainText
    }

    func sealedBoxOpen(cipherText: Data, publicKey: Data, secretKey: Data) throws -> Data {
        let plainTextB64 = try withCStrings([
            cipherText.base64EncodedString(),
            publicKey.base64EncodedString(),
            secretKey.base64EncodedString(),
        ]) { ptrs in
            try callForStringOutput { out, outError in
                rustSealedBoxOpen(ptrs[0], ptrs[1], ptrs[2], out, outError)
            }
        }

        guard let plainText = Data(base64Encoded: plainTextB64) else {
            throw RustCryptoBridgeError.invalidOutput("Failed to decode decrypted SealedBox payload")
        }
        return plainText
    }

    func decryptSecretStream(encryptedData: Data, key: Data, header: Data) throws -> Data {
        let plainTextB64 = try withCStrings([
            encryptedData.base64EncodedString(),
            header.base64EncodedString(),
            key.base64EncodedString(),
        ]) { ptrs in
            try callForStringOutput { out, outError in
                rustDecryptSecretStream(ptrs[0], ptrs[1], ptrs[2], out, outError)
            }
        }

        guard let plainText = Data(base64Encoded: plainTextB64) else {
            throw RustCryptoBridgeError.invalidOutput("Failed to decode decrypted secret stream payload")
        }
        return plainText
    }

    func blake2bHashHex(_ data: Data) throws -> String {
        var output: UnsafeMutablePointer<CChar>? = nil
        var error: UnsafeMutablePointer<CChar>? = nil
        var zeroByte: UInt8 = 0

        let status: Int32 = data.withUnsafeBytes { bytes in
            let pointer = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
            return withUnsafePointer(to: &zeroByte) { zeroPtr in
                rustBlake2bHashHex(pointer ?? zeroPtr, data.count, &output, &error)
            }
        }

        defer {
            freeRustString(output)
            freeRustString(error)
        }

        if status != 0 {
            let message = error.map { String(cString: $0) } ?? "Unknown Rust error"
            throw RustCryptoBridgeError.operationFailed(message)
        }

        guard let output, let hash = String(validatingUTF8: output) else {
            throw RustCryptoBridgeError.invalidOutput("Failed to decode BLAKE2b hash")
        }

        return hash
    }

    private func withCStrings<T>(_ values: [String], _ operation: ([UnsafePointer<CChar>?]) throws -> T) throws -> T {
        func recurse(_ index: Int, _ pointers: [UnsafePointer<CChar>?]) throws -> T {
            if index == values.count {
                return try operation(pointers)
            }

            return try values[index].withCString { ptr in
                try recurse(index + 1, pointers + [ptr])
            }
        }

        return try recurse(0, [])
    }

    private func callForStringOutput(
        _ call: (
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        ) -> Int32
    ) throws -> String {
        var output: UnsafeMutablePointer<CChar>? = nil
        var error: UnsafeMutablePointer<CChar>? = nil

        let status = call(&output, &error)

        defer {
            freeRustString(output)
            freeRustString(error)
        }

        if status != 0 {
            let message = error.map { String(cString: $0) } ?? "Unknown Rust error"
            throw RustCryptoBridgeError.operationFailed(message)
        }

        guard let output, let value = String(validatingUTF8: output) else {
            throw RustCryptoBridgeError.invalidOutput("Missing or invalid UTF-8 output")
        }

        return value
    }

    private func callForTwoStringOutputs(
        _ call: (
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        ) -> Int32
    ) throws -> (String, String) {
        var output1: UnsafeMutablePointer<CChar>? = nil
        var output2: UnsafeMutablePointer<CChar>? = nil
        var error: UnsafeMutablePointer<CChar>? = nil

        let status = call(&output1, &output2, &error)

        defer {
            freeRustString(output1)
            freeRustString(output2)
            freeRustString(error)
        }

        if status != 0 {
            let message = error.map { String(cString: $0) } ?? "Unknown Rust error"
            throw RustCryptoBridgeError.operationFailed(message)
        }

        guard let output1,
              let output2,
              let value1 = String(validatingUTF8: output1),
              let value2 = String(validatingUTF8: output2) else {
            throw RustCryptoBridgeError.invalidOutput("Missing or invalid UTF-8 keypair output")
        }

        return (value1, value2)
    }

    private func freeRustString(_ pointer: UnsafeMutablePointer<CChar>?) {
        guard let pointer else {
            return
        }
        rustStringFree(pointer)
    }
}
