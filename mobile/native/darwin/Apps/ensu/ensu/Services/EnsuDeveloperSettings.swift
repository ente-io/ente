import Foundation
#if canImport(EnteNetwork)
import EnteNetwork
#else
struct NetworkConfiguration {
    let apiEndpoint: URL

    static var `default`: NetworkConfiguration {
        NetworkConfiguration(apiEndpoint: URL(string: "https://api.ente.io")!)
    }

    static func selfHosted(baseURL: URL) -> NetworkConfiguration {
        NetworkConfiguration(apiEndpoint: baseURL)
    }
}
#endif

enum EnsuDeveloperSettings {
    private static let endpointKey = "ensu.customEndpoint"

    static var currentEndpoint: URL? {
        if let envEndpoint = endpointURL(from: ProcessInfo.processInfo.environment["ENTE_API_ENDPOINT"]) {
            return envEndpoint
        }
        if let storedEndpoint = endpointURL(from: UserDefaults.standard.string(forKey: endpointKey)) {
            return storedEndpoint
        }
        return nil
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

    private static func endpointURL(from value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        let normalized = normalize(value)
        return URL(string: normalized)
    }

    static func normalize(_ value: String) -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return trimmed
    }
}
