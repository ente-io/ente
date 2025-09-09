import Foundation
import EnteCore

// MARK: - API Endpoint Protocol

public protocol APIEndpoint {
    var domain: APIDomain { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
}

// MARK: - Authentication Endpoints

public enum AuthEndpoint: APIEndpoint {
    case getSRPAttributes(email: String)
    case createSRPSession(srpUserID: String, clientPub: String)
    case verifySRPSession(srpUserID: String, sessionID: String, clientM1: String)
    case sendLoginOTP(email: String, purpose: String)
    case verifyEmail(email: String, otp: String)
    case verifyTOTP(sessionID: String, otp: String)
    case getTokenForPasskeySession(sessionID: String)
    
    public var domain: APIDomain { 
        return .api
    }
    
    public var path: String {
        switch self {
        case .getSRPAttributes:
            return "/users/srp/attributes"
        case .createSRPSession:
            return "/users/srp/create-session"
        case .verifySRPSession:
            return "/users/srp/verify-session"
        case .sendLoginOTP:
            return "/users/ott"
        case .verifyEmail:
            return "/users/verify-email"
        case .verifyTOTP:
            return "/users/two-factor/verify"
        case .getTokenForPasskeySession:
            return "/users/two-factor/passkeys/get-token"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .getSRPAttributes, .getTokenForPasskeySession:
            return .GET
        case .createSRPSession, .verifySRPSession, .sendLoginOTP, .verifyEmail, .verifyTOTP:
            return .POST
        }
    }
    
    public var parameters: [String: Any]? {
        switch self {
        case .getSRPAttributes(let email):
            return ["email": email]
        case .createSRPSession(let srpUserID, let clientPub):
            return ["srpUserID": srpUserID, "srpA": clientPub]
        case .verifySRPSession(let srpUserID, let sessionID, let clientM1):
            return ["srpUserID": srpUserID, "sessionID": sessionID, "srpM1": clientM1]
        case .sendLoginOTP(let email, let purpose):
            return ["email": email, "purpose": purpose]
        case .verifyEmail(let email, let otp):
            return ["email": email, "ott": otp]
        case .verifyTOTP(let sessionID, let otp):
            return ["sessionID": sessionID, "code": otp]
        case .getTokenForPasskeySession(let sessionID):
            return ["sessionID": sessionID]
        }
    }
    
    public var headers: [String: String]? { return nil }
}

// MARK: - Cast Endpoints (TV-specific)

public enum CastEndpoint: APIEndpoint {
    case registerDevice
    case getDeviceInfo(deviceCode: String)
    case getCastData(deviceCode: String)
    case insertCastData([String: Any])
    case revokeAllTokens
    case getThumbnail(fileID: FileID)
    case getFile(fileID: FileID)
    case getDiff(sinceTime: Int64)
    case getCollection
    
    public var domain: APIDomain { 
        return .cast  // All cast operations use cast domain
    }
    
    public var path: String {
        switch self {
        case .registerDevice:
            return "/cast/device-info"
        case .getDeviceInfo(let code):
            return "/cast/device-info/\(code)"
        case .getCastData(let code):
            return "/cast/cast-data/\(code)"
        case .insertCastData:
            return "/cast/cast-data"
        case .revokeAllTokens:
            return "/cast/revoke-all-tokens"
        case .getThumbnail(let fileID):
            return "/files/preview/\(fileID.rawValue)"
        case .getFile(let fileID):
            return "/files/download/\(fileID.rawValue)"
        case .getDiff:
            return "/diff"
        case .getCollection:
            return "/info"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .registerDevice, .insertCastData:
            return .POST
        case .revokeAllTokens:
            return .DELETE
        case .getDeviceInfo, .getCastData, .getThumbnail, .getFile, .getDiff, .getCollection:
            return .GET
        }
    }
    
    public var parameters: [String: Any]? {
        switch self {
        case .getDiff(let sinceTime):
            return ["sinceTime": sinceTime]
        case .insertCastData(let data):
            return data
        default:
            return nil
        }
    }
    
    public var headers: [String: String]? { return nil }
}

// MARK: - User Endpoints

public enum UserEndpoint: APIEndpoint {
    case getUserDetails(fetchMemoryCount: Bool)
    case logout
    case getActiveSessions
    case terminateSession(sessionID: String)
    case deleteUser(challenge: String)
    case getDeleteChallenge
    
    public var domain: APIDomain { return .api }
    
    public var path: String {
        switch self {
        case .getUserDetails:
            return "/users/details/v2"
        case .logout:
            return "/users/logout"
        case .getActiveSessions:
            return "/users/sessions"
        case .terminateSession:
            return "/users/session"
        case .deleteUser:
            return "/users/delete"
        case .getDeleteChallenge:
            return "/users/delete-challenge"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .getUserDetails, .getActiveSessions, .getDeleteChallenge:
            return .GET
        case .logout:
            return .POST
        case .terminateSession, .deleteUser:
            return .DELETE
        }
    }
    
    public var parameters: [String: Any]? {
        switch self {
        case .getUserDetails(let fetchMemoryCount):
            return ["memoryCount": fetchMemoryCount]
        case .deleteUser(let challenge):
            return ["challenge": challenge]
        default:
            return nil
        }
    }
    
    public var headers: [String: String]? { return nil }
}