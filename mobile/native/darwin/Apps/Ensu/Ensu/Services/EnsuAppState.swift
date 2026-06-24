import Foundation

@MainActor
final class EnsuAppState: ObservableObject {
    @Published private(set) var isLoggedIn: Bool

    init() {
        self.isLoggedIn = CredentialStore.shared.hasConfiguredAccount
    }

    func refreshLoginState() {
        isLoggedIn = CredentialStore.shared.hasConfiguredAccount
    }

    func logout() {
        CredentialStore.shared.clear()
        refreshLoginState()
    }
}
