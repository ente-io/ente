import Foundation

public enum CastSessionState: Equatable {
    case idle
    case registering
    case waitingForPairing(deviceCode: String)
    case connected(CastPayload)
    case error(String)
}

public struct CastPayload: Codable, Equatable {
    public let collectionID: CollectionID
    public let collectionKey: String
    public let castToken: String
    
    public init(collectionID: CollectionID, collectionKey: String, castToken: String) {
        self.collectionID = collectionID
        self.collectionKey = collectionKey
        self.castToken = castToken
    }
}

public struct CastDevice: Codable, Equatable {
    public let deviceCode: String
    public let publicKey: String
    public let privateKey: String
    
    public init(deviceCode: String, publicKey: String, privateKey: String) {
        self.deviceCode = deviceCode
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
}

@MainActor
public class CastSession: ObservableObject {
    @Published public var state: CastSessionState = .idle
    @Published public var isActive: Bool = false
    
    public var deviceCode: String? {
        if case .waitingForPairing(let code) = state {
            return code
        }
        return nil
    }
    
    public var payload: CastPayload? {
        if case .connected(let payload) = state {
            return payload
        }
        return nil
    }
    
    public init() {}
    
    public func setState(_ newState: CastSessionState) {
        state = newState
        isActive = !isIdle
    }
    
    public var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }
    
    public var isWaitingForPairing: Bool {
        if case .waitingForPairing = state {
            return true
        }
        return false
    }
    
    public var isConnected: Bool {
        if case .connected = state {
            return true
        }
        return false
    }
    
    public var hasError: Bool {
        if case .error = state {
            return true
        }
        return false
    }
}