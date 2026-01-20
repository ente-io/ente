import Foundation
import Security

final class CredentialStore {
    static let shared = CredentialStore()

    private init() {}

    private let keychainService = "io.ente.ensu"

    private enum DefaultsKey {
        static let email = "ensu.email"
        static let userId = "ensu.userId"
    }

    private enum KeychainAccount {
        static let token = "ensu.token"
        static let masterKey = "ensu.masterKey"
        static let secretKey = "ensu.secretKey"
        static let chatDbKey = "ensu.chatDbKey"
    }

    var email: String? {
        UserDefaults.standard.string(forKey: DefaultsKey.email)
    }

    var userId: Int64? {
        let value = UserDefaults.standard.object(forKey: DefaultsKey.userId) as? NSNumber
        return value?.int64Value
    }

    var token: String? {
        guard let data = try? KeychainStore.get(service: keychainService, account: KeychainAccount.token) else {
            return nil
        }
        guard let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        // Normalize to the padded base64url form (Go's `base64.URLEncoding`).
        // Older Ensu builds stored the token without padding, which breaks server lookups.
        let remainder = token.count % 4
        if remainder == 0 {
            return token
        }
        return token + String(repeating: "=", count: 4 - remainder)
    }

    var hasConfiguredAccount: Bool {
        token?.isEmpty == false &&
            email?.isEmpty == false &&
            KeychainStore.exists(service: keychainService, account: KeychainAccount.masterKey) &&
            KeychainStore.exists(service: keychainService, account: KeychainAccount.secretKey)
    }

    func save(email: String, userId: Int64, masterKey: Data, secretKey: Data, token: String) throws {
        UserDefaults.standard.set(email, forKey: DefaultsKey.email)
        UserDefaults.standard.set(NSNumber(value: userId), forKey: DefaultsKey.userId)

        try KeychainStore.set(Data(token.utf8), service: keychainService, account: KeychainAccount.token)
        try KeychainStore.set(masterKey, service: keychainService, account: KeychainAccount.masterKey)
        try KeychainStore.set(secretKey, service: keychainService, account: KeychainAccount.secretKey)
    }

    /// Returns a stable 32-byte key for encrypting the local chat DB.
    ///
    /// Rules:
    /// - If already stored, reuse it.
    /// - Else, if the account master key exists and is 32 bytes, pin it as the chat DB key.
    /// - Else, generate a random 32-byte key and persist it.
    func getOrCreateChatDbKey() -> Data {
        if let existing = try? KeychainStore.get(service: keychainService, account: KeychainAccount.chatDbKey), existing.count == 32 {
            return existing
        }

        if let master = try? KeychainStore.get(service: keychainService, account: KeychainAccount.masterKey), master.count == 32 {
            try? KeychainStore.set(master, service: keychainService, account: KeychainAccount.chatDbKey)
            return master
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            // Fallback to less ideal randomness if SecRandom fails (shouldn't happen on iOS).
            bytes = (0..<32).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
        }
        let data = Data(bytes)
        try? KeychainStore.set(data, service: keychainService, account: KeychainAccount.chatDbKey)
        return data
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.email)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.userId)

        try? KeychainStore.delete(service: keychainService, account: KeychainAccount.token)
        try? KeychainStore.delete(service: keychainService, account: KeychainAccount.masterKey)
        try? KeychainStore.delete(service: keychainService, account: KeychainAccount.secretKey)
        // Note: keep chatDbKey to preserve local chats across sign-out.
    }
}
