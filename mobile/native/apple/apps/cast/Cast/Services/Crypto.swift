import Foundation

enum Crypto {
    static func generateKeyPair() throws -> (publicKey: Data, privateKey: Data) {
        let keyPair = Cast.generateKeyPair()
        return (publicKey: keyPair.publicKey, privateKey: keyPair.privateKey)
    }

    static func secretBoxOpen(cipherText: Data, nonce: Data, key: Data) throws -> Data {
        try Cast.openSecretBox(ciphertext: cipherText, nonce: nonce, key: key)
    }

    static func sealedBoxOpen(cipherText: Data, publicKey: Data, secretKey: Data) throws -> Data {
        try Cast.openSealedBox(ciphertext: cipherText, publicKey: publicKey, privateKey: secretKey)
    }

    static func decryptSecretStream(encryptedData: Data, key: Data, header: Data) throws -> Data {
        try Cast.decryptSecretStream(encryptedData: encryptedData, header: header, key: key)
    }
}
