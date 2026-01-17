import Foundation

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
        return String(data: data, encoding: .utf8)
    }

    var hasConfiguredAccount: Bool {
        token?.isEmpty == false && email?.isEmpty == false
    }

    func save(email: String, userId: Int64, masterKey: Data, secretKey: Data, token: String) throws {
        UserDefaults.standard.set(email, forKey: DefaultsKey.email)
        UserDefaults.standard.set(NSNumber(value: userId), forKey: DefaultsKey.userId)

        try KeychainStore.set(Data(token.utf8), service: keychainService, account: KeychainAccount.token)
        try KeychainStore.set(masterKey, service: keychainService, account: KeychainAccount.masterKey)
        try KeychainStore.set(secretKey, service: keychainService, account: KeychainAccount.secretKey)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.email)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.userId)

        try? KeychainStore.delete(service: keychainService, account: KeychainAccount.token)
        try? KeychainStore.delete(service: keychainService, account: KeychainAccount.masterKey)
        try? KeychainStore.delete(service: keychainService, account: KeychainAccount.secretKey)
    }
}
