import Foundation
import Tagged

// MARK: - Basic Types

/// Strongly typed User ID
public typealias UserID = Tagged<UserIDTag, Int64>
public enum UserIDTag {}

/// Strongly typed File ID  
public typealias FileID = Tagged<FileIDTag, Int64>
public enum FileIDTag {}

/// Strongly typed Collection ID
public typealias CollectionID = Tagged<CollectionIDTag, Int64>
public enum CollectionIDTag {}

// MARK: - App Types

public enum EnteApp: String, CaseIterable, Codable {
    case photos = "photos"
    case auth = "auth"
    case locker = "locker"
    case cast = "cast"
    
    public var displayName: String {
        switch self {
        case .photos: return "Ente Photos"
        case .auth: return "Ente Auth"
        case .locker: return "Ente Locker"
        case .cast: return "Ente Cast"
        }
    }
    
    public var packageIdentifier: String {
        switch self {
        case .photos: return "io.ente.photos"
        case .auth: return "io.ente.auth"
        case .locker: return "io.ente.locker"
        case .cast: return "io.ente.photos.cast"
        }
    }
}

// MARK: - Platform Detection

public enum EntePlatform: String {
    case iOS = "ios"
    case tvOS = "tvos"
    case macOS = "macos"
    
    public static var current: EntePlatform {
        #if os(iOS)
        return .iOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(macOS)
        return .macOS
        #endif
    }
    
    public var userAgent: String {
        switch self {
        case .iOS: return "EnteNative-iOS"
        case .tvOS: return "EnteNative-tvOS"
        case .macOS: return "EnteNative-macOS"
        }
    }
}

// MARK: - Encrypted Data

public struct EncryptedData: Codable, Equatable {
    public let data: String
    public let nonce: String?
    
    public init(data: String, nonce: String? = nil) {
        self.data = data
        self.nonce = nonce
    }
}

// MARK: - Error Types

public enum EnteError: Error, Equatable {
    case networkError(String)
    case authenticationError(String)
    case cryptographicError(String)
    case configurationError(String)
    case invalidResponse
    case unauthorized
    case serverError(Int, String?)
    
    public var localizedDescription: String {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .cryptographicError(let message):
            return "Cryptographic error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        }
    }
}

// MARK: - Common Response Types

public struct EmptyResponse: Codable {
    public init() {}
}

public struct ErrorResponse: Codable {
    public let code: String?
    public let message: String
    
    public init(code: String? = nil, message: String) {
        self.code = code
        self.message = message
    }
}
