import Foundation

enum CryptoError: Error, LocalizedError {
    case failed(String)
    case invalidOutput(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message), .invalidOutput(let message):
            return message
        }
    }
}

@_silgen_name("ente_crypto_string_free")
private func rustStringFree(_ ptr: UnsafeMutablePointer<CChar>?)

@_silgen_name("ente_crypto_generate_keypair_b64")
private func rustGenerateKeyPair(
    _ outPublicKeyB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outSecretKeyB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_crypto_secretbox_open_b64")
private func rustSecretBoxOpen(
    _ cipherTextB64: UnsafePointer<CChar>?,
    _ nonceB64: UnsafePointer<CChar>?,
    _ keyB64: UnsafePointer<CChar>?,
    _ outPlainTextB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_crypto_sealed_box_open_b64")
private func rustSealedBoxOpen(
    _ cipherTextB64: UnsafePointer<CChar>?,
    _ publicKeyB64: UnsafePointer<CChar>?,
    _ secretKeyB64: UnsafePointer<CChar>?,
    _ outPlainTextB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

@_silgen_name("ente_crypto_secretstream_decrypt_b64")
private func rustDecryptSecretStream(
    _ encryptedDataB64: UnsafePointer<CChar>?,
    _ headerB64: UnsafePointer<CChar>?,
    _ keyB64: UnsafePointer<CChar>?,
    _ outPlainTextB64: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ outError: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32

enum Crypto {
    static func generateKeyPair() throws -> (publicKey: Data, privateKey: Data) {
        let (publicKey, privateKey) = try callForTwoStrings { out1, out2, error in
            rustGenerateKeyPair(out1, out2, error)
        }
        return (
            publicKey: try decodeBase64(publicKey, "public key"),
            privateKey: try decodeBase64(privateKey, "private key")
        )
    }

    static func secretBoxOpen(cipherText: Data, nonce: Data, key: Data) throws -> Data {
        guard nonce.count == 24, key.count == 32 else {
            throw CryptoError.failed("invalid SecretBox input")
        }

        let plainText = try callForString(
            cipherText.base64EncodedString(),
            nonce.base64EncodedString(),
            key.base64EncodedString()
        ) { cipherText, nonce, key, output, error in
            rustSecretBoxOpen(cipherText, nonce, key, output, error)
        }
        return try decodeBase64(plainText, "SecretBox plaintext")
    }

    static func sealedBoxOpen(cipherText: Data, publicKey: Data, secretKey: Data) throws -> Data {
        guard publicKey.count == 32, secretKey.count == 32 else {
            throw CryptoError.failed("invalid SealedBox input")
        }

        let plainText = try callForString(
            cipherText.base64EncodedString(),
            publicKey.base64EncodedString(),
            secretKey.base64EncodedString()
        ) { cipherText, publicKey, secretKey, output, error in
            rustSealedBoxOpen(cipherText, publicKey, secretKey, output, error)
        }
        return try decodeBase64(plainText, "SealedBox plaintext")
    }

    static func decryptSecretStream(encryptedData: Data, key: Data, header: Data) throws -> Data {
        guard key.count == 32, header.count == 24 else {
            throw CryptoError.failed("invalid secretstream input")
        }

        let plainText = try callForString(
            encryptedData.base64EncodedString(),
            header.base64EncodedString(),
            key.base64EncodedString()
        ) { encryptedData, header, key, output, error in
            rustDecryptSecretStream(encryptedData, header, key, output, error)
        }
        return try decodeBase64(plainText, "secretstream plaintext")
    }

    private static func decodeBase64(_ value: String, _ label: String) throws -> Data {
        guard let data = Data(base64Encoded: value) else {
            throw CryptoError.invalidOutput("invalid base64 \(label)")
        }
        return data
    }

    private static func callForString(
        _ input1: String,
        _ input2: String,
        _ input3: String,
        _ call: (
            UnsafePointer<CChar>?,
            UnsafePointer<CChar>?,
            UnsafePointer<CChar>?,
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        ) -> Int32
    ) throws -> String {
        var output: UnsafeMutablePointer<CChar>? = nil
        var error: UnsafeMutablePointer<CChar>? = nil
        let status = input1.withCString { cInput1 in
            input2.withCString { cInput2 in
                input3.withCString { cInput3 in
                    call(cInput1, cInput2, cInput3, &output, &error)
                }
            }
        }

        defer {
            rustStringFree(output)
            rustStringFree(error)
        }

        guard status == 0 else {
            throw CryptoError.failed(error.map { String(cString: $0) } ?? "unknown Rust crypto error")
        }
        guard let output, let value = String(validatingUTF8: output) else {
            throw CryptoError.invalidOutput("missing Rust crypto output")
        }
        return value
    }

    private static func callForTwoStrings(
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
            rustStringFree(output1)
            rustStringFree(output2)
            rustStringFree(error)
        }

        guard status == 0 else {
            throw CryptoError.failed(error.map { String(cString: $0) } ?? "unknown Rust crypto error")
        }
        guard let output1,
              let output2,
              let value1 = String(validatingUTF8: output1),
              let value2 = String(validatingUTF8: output2) else {
            throw CryptoError.invalidOutput("missing Rust crypto output")
        }
        return (value1, value2)
    }
}
