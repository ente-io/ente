import Foundation
import EnteNetwork

final class EnsuAuthTokenProvider: AuthTokenProvider {
    func getAuthToken() async throws -> String? {
        return CredentialStore.shared.token
    }
}
