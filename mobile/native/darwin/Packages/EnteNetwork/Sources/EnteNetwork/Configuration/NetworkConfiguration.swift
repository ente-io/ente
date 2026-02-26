import Foundation
import EnteCore

// MARK: - Network Configuration

public struct NetworkConfiguration {
    public let apiEndpoint: URL
    public let accountsEndpoint: URL?
    public let castEndpoint: URL?
    public let publicAlbumsEndpoint: URL?
    public let familyEndpoint: URL?
    
    public init(
        apiEndpoint: URL,
        accountsEndpoint: URL? = nil,
        castEndpoint: URL? = nil,
        publicAlbumsEndpoint: URL? = nil,
        familyEndpoint: URL? = nil
    ) {
        self.apiEndpoint = apiEndpoint
        self.accountsEndpoint = accountsEndpoint
        self.castEndpoint = castEndpoint
        self.publicAlbumsEndpoint = publicAlbumsEndpoint
        self.familyEndpoint = familyEndpoint
    }
    
    // Convenience initializer for self-hosted instances
    public static func selfHosted(baseURL: URL) -> NetworkConfiguration {
        return NetworkConfiguration(
            apiEndpoint: baseURL,
            accountsEndpoint: baseURL.appendingPathComponent("accounts"),
            castEndpoint: baseURL.appendingPathComponent("cast"),
            publicAlbumsEndpoint: baseURL.appendingPathComponent("public-albums"),
            familyEndpoint: baseURL.appendingPathComponent("family")
        )
    }
    
    // Default Ente.io configuration
    public static let `default` = NetworkConfiguration(
        apiEndpoint: URL(string: "https://api.ente.io")!,
        accountsEndpoint: URL(string: "https://accounts.ente.io"),
        castEndpoint: URL(string: "https://api.ente.io"), // Fix: Use same endpoint as web app
        publicAlbumsEndpoint: URL(string: "https://albums.ente.io"),
        familyEndpoint: URL(string: "https://family.ente.io")
    )
}

// MARK: - Environment Configuration

public enum EnteEnvironment {
    case production
    case staging
    case development
    case selfHosted(URL)
    
    public var networkConfiguration: NetworkConfiguration {
        switch self {
        case .production:
            return .default
        case .staging:
            return NetworkConfiguration(
                apiEndpoint: URL(string: "https://api.staging.ente.io")!,
                accountsEndpoint: URL(string: "https://accounts.staging.ente.io"),
                castEndpoint: URL(string: "https://cast.staging.ente.io")
            )
        case .development:
            return NetworkConfiguration(
                apiEndpoint: URL(string: "http://localhost:8080")!
            )
        case .selfHosted(let baseURL):
            return NetworkConfiguration.selfHosted(baseURL: baseURL)
        }
    }
}

// MARK: - API Domain

public enum APIDomain {
    case api        // Main API server
    case accounts   // Account management
    case cast       // TV/Cast operations
    case publicAlbums // Public album sharing
    case family     // Family plan management
}

// MARK: - Endpoint Resolver

public class EndpointResolver {
    private let configuration: NetworkConfiguration
    
    public init(configuration: NetworkConfiguration) {
        self.configuration = configuration
    }
    
    public func resolveURL(for endpoint: APIEndpoint) -> URL {
        let baseURL = resolveBaseURL(for: endpoint.domain)
        return baseURL.appendingPathComponent(endpoint.path)
    }
    
    private func resolveBaseURL(for domain: APIDomain) -> URL {
        switch domain {
        case .api:
            return configuration.apiEndpoint
        case .accounts:
            return configuration.accountsEndpoint ?? configuration.apiEndpoint
        case .cast:
            return configuration.castEndpoint ?? configuration.apiEndpoint
        case .publicAlbums:
            return configuration.publicAlbumsEndpoint ?? configuration.apiEndpoint
        case .family:
            return configuration.familyEndpoint ?? configuration.apiEndpoint
        }
    }
}