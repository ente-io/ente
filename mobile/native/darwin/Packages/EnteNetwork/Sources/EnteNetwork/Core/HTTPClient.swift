import Foundation
import EnteCore
import Logging

// MARK: - HTTP Method

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Auth Token Provider

public protocol AuthTokenProvider {
    func getAuthToken() async throws -> String?
}

// MARK: - HTTP Headers Builder

public struct HTTPHeaders {
    private var headers: [String: String] = [:]
    
    public init() {}
    
    public mutating func add(name: String, value: String) {
        headers[name] = value
    }
    
    public func build() -> [String: String] {
        return headers
    }
}

// MARK: - Request Headers Manager

public class RequestHeadersManager {
    private let logger = Logger(label: "RequestHeadersManager")
    
    public init() {}
    
    /// Builds headers based on mobile packages pattern - mirrors network.dart
    public func buildHeaders(
        app: EnteApp,
        authTokenProvider: AuthTokenProvider? = nil
    ) async -> [String: String] {
        var headers = HTTPHeaders()
        
        // Platform-specific User-Agent (mirrors mobile pattern)
        let platform = EntePlatform.current
        headers.add(name: "User-Agent", value: platform.userAgent)
        
        // Client version - using bundle version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers.add(name: "X-Client-Version", value: version)
        }
        
        // Client package - mirrors mobile packageName pattern
        headers.add(name: "X-Client-Package", value: app.packageIdentifier)
        
        // Request ID for tracing (mirrors mobile x-request-id)
        headers.add(name: "x-request-id", value: UUID().uuidString)
        
        // Auth token if available (mirrors mobile X-Auth-Token)
        if let token = try? await authTokenProvider?.getAuthToken() {
            headers.add(name: "X-Auth-Token", value: token)
        }
        
        return headers.build()
    }
}

// MARK: - HTTP Client

public class HTTPClient {
    private let session: URLSession
    private let headersManager: RequestHeadersManager
    private let logger = Logger(label: "HTTPClient")
    
    public init(
        session: URLSession = .shared,
        headersManager: RequestHeadersManager = RequestHeadersManager()
    ) {
        self.session = session
        self.headersManager = headersManager
    }
    
    public func request<T: Codable>(
        url: URL,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        var finalURL = url
        
        // For GET requests, add parameters as query parameters
        if let parameters = parameters, method == .GET {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            var queryItems = components.queryItems ?? []
            
            for (key, value) in parameters {
                // URLQueryItem will handle proper encoding automatically
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
            
            components.queryItems = queryItems
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            finalURL = components.url!
            print("🌐 Final URL with encoded parameters: \(finalURL)")
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        
        // Add headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add JSON body for POST/PUT requests
        if let parameters = parameters, 
           method == .POST || method == .PUT || method == .PATCH {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        
        logger.debug("Making \(method.rawValue) request to \(finalURL)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EnteError.networkError("Invalid response type")
        }
        
        logger.debug("Response status: \(httpResponse.statusCode)")
        
        // Handle error responses
        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw EnteError.serverError(httpResponse.statusCode, errorResponse.message)
            } else {
                throw EnteError.serverError(httpResponse.statusCode, nil)
            }
        }
        
        // Handle empty responses
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        // Decode JSON response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed to decode response: \(error)")
            throw EnteError.invalidResponse
        }
    }
    
    public func upload(
        url: URL,
        data: Data,
        headers: [String: String]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        // Add headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        logger.debug("Uploading data to \(url)")
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EnteError.networkError("Invalid response type")
        }
        
        if httpResponse.statusCode >= 400 {
            throw EnteError.serverError(httpResponse.statusCode, nil)
        }
        
        return responseData
    }
    
    public func download(
        url: URL,
        headers: [String: String]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        logger.debug("Downloading from \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EnteError.networkError("Invalid response type")
        }
        
        if httpResponse.statusCode >= 400 {
            throw EnteError.serverError(httpResponse.statusCode, nil)
        }
        
        return data
    }
}