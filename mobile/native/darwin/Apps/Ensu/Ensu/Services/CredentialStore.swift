import Foundation
import Security

final class CredentialStore {
    static let shared = CredentialStore()

    private init() {}

    private let keychainService = "io.ente.ensu"

    private enum KeychainAccount {
        static let masterKey = "ensu.masterKey"
        static let chatDbKey = "ensu.chatDbKey"
    }

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
            bytes = (0..<32).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
        }
        let data = Data(bytes)
        try? KeychainStore.set(data, service: keychainService, account: KeychainAccount.chatDbKey)
        return data
    }
}
