import Foundation
import EnteNetwork

enum EnsuDeveloperSettings {
    private static let endpointKey = "ensu.customEndpoint"

    static var currentEndpoint: URL? {
        guard let stored = UserDefaults.standard.string(forKey: endpointKey),
              let url = URL(string: stored) else {
            return nil
        }
        return url
    }

    static var currentEndpointString: String {
        if let currentEndpoint {
            return currentEndpoint.absoluteString
        }
        return NetworkConfiguration.default.apiEndpoint.absoluteString
    }

    static var networkConfiguration: NetworkConfiguration {
        if let endpoint = currentEndpoint {
            return NetworkConfiguration.selfHosted(baseURL: endpoint)
        }
        return .default
    }

    static func setEndpoint(_ url: URL?) {
        if let url {
            let normalized = normalize(url.absoluteString)
            UserDefaults.standard.set(normalized, forKey: endpointKey)
        } else {
            UserDefaults.standard.removeObject(forKey: endpointKey)
        }
    }

    static func normalize(_ value: String) -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return trimmed
    }
}
