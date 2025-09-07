import Foundation
import EnteCore
import Logging

// MARK: - API Client

public class APIClient {
    private let httpClient: HTTPClient
    private let endpointResolver: EndpointResolver
    private let headersManager: RequestHeadersManager
    private let authTokenProvider: AuthTokenProvider?
    private let app: EnteApp
    private let logger = Logger(label: "APIClient")
    
    public init(
        configuration: NetworkConfiguration,
        app: EnteApp,
        authTokenProvider: AuthTokenProvider? = nil,
        httpClient: HTTPClient = HTTPClient()
    ) {
        self.httpClient = httpClient
        self.endpointResolver = EndpointResolver(configuration: configuration)
        self.headersManager = RequestHeadersManager()
        self.authTokenProvider = authTokenProvider
        self.app = app
    }
    
    public func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        let url = endpointResolver.resolveURL(for: endpoint)
        let headers = await buildHeaders(for: endpoint)
        
        logger.debug("Making request to \(url)")
        
        return try await httpClient.request(
            url: url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            headers: headers,
            responseType: responseType
        )
    }
    
    public func request(_ endpoint: APIEndpoint) async throws -> EmptyResponse {
        return try await request(endpoint, responseType: EmptyResponse.self)
    }
    
    public func upload(_ endpoint: APIEndpoint, data: Data) async throws -> Data {
        let url = endpointResolver.resolveURL(for: endpoint)
        let headers = await buildHeaders(for: endpoint)
        
        return try await httpClient.upload(url: url, data: data, headers: headers)
    }
    
    public func download(_ endpoint: APIEndpoint) async throws -> Data {
        let url = endpointResolver.resolveURL(for: endpoint)
        let headers = await buildHeaders(for: endpoint)
        
        return try await httpClient.download(url: url, headers: headers)
    }
    
    private func buildHeaders(for endpoint: APIEndpoint) async -> [String: String] {
        // Start with endpoint-specific headers
        var headers = endpoint.headers ?? [:]
        
        // Add common headers (mirrors mobile network.dart pattern)
        let commonHeaders = await headersManager.buildHeaders(
            app: app,
            authTokenProvider: authTokenProvider
        )
        
        // Merge headers (endpoint headers take precedence)
        for (key, value) in commonHeaders {
            if headers[key] == nil {
                headers[key] = value
            }
        }
        
        return headers
    }
}

// MARK: - Simple Auth Token Provider

public class SimpleAuthTokenProvider: AuthTokenProvider {
    private var token: String?
    
    public init(token: String? = nil) {
        self.token = token
    }
    
    public func getAuthToken() async throws -> String? {
        return token
    }
    
    public func setAuthToken(_ token: String?) {
        self.token = token
    }
}