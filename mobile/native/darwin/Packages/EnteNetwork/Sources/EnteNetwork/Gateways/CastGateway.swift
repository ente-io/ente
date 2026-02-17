import Foundation
import EnteCore
import Logging

// MARK: - Cast Models

public struct CastDevice: Codable {
    public let code: String
    public let deviceID: String?
    public let publicKey: String?
    
    public init(code: String, deviceID: String?, publicKey: String?) {
        self.code = code
        self.deviceID = deviceID
        self.publicKey = publicKey
    }
}

public struct CastData: Codable {
    public let deviceCode: String
    public let collectionID: CollectionID
    public let castToken: String
    
    public init(deviceCode: String, collectionID: CollectionID, castToken: String) {
        self.deviceCode = deviceCode
        self.collectionID = collectionID
        self.castToken = castToken
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "deviceCode": deviceCode,
            "collectionID": collectionID.rawValue,
            "castToken": castToken
        ]
    }
}

public struct CastDiff: Codable {
    public let diff: [CastFile]
    public let hasMore: Bool
    
    public init(diff: [CastFile], hasMore: Bool) {
        self.diff = diff
        self.hasMore = hasMore
    }
}

public struct CastFile: Codable {
    public let id: FileID
    public let updationTime: Int64
    public let isDeleted: Bool
    
    public init(id: FileID, updationTime: Int64, isDeleted: Bool) {
        self.id = id
        self.updationTime = updationTime
        self.isDeleted = isDeleted
    }
}

public struct CastCollection: Codable {
    public let id: CollectionID
    public let name: String
    public let fileCount: Int
    
    public init(id: CollectionID, name: String, fileCount: Int) {
        self.id = id
        self.name = name
        self.fileCount = fileCount
    }
}

// MARK: - Cast Gateway

public class CastGateway {
    private let client: APIClient
    private let logger = Logger(label: "CastGateway")
    
    internal init(client: APIClient) {
        self.client = client
    }
    
    // MARK: - Cast Device Management
    
    public func registerDevice() async throws -> CastDevice {
        logger.info("Registering cast device")
        
        return try await client.request(
            CastEndpoint.registerDevice,
            responseType: CastDevice.self
        )
    }
    
    public func getDeviceInfo(deviceCode: String) async throws -> CastDevice {
        logger.info("Getting device info for code: \(deviceCode)")
        
        return try await client.request(
            CastEndpoint.getDeviceInfo(deviceCode: deviceCode),
            responseType: CastDevice.self
        )
    }
    
    public func getCastData(deviceCode: String) async throws -> CastData {
        logger.info("Getting cast data for device: \(deviceCode)")
        
        return try await client.request(
            CastEndpoint.getCastData(deviceCode: deviceCode),
            responseType: CastData.self
        )
    }
    
    public func insertCastData(_ data: CastData) async throws {
        logger.info("Inserting cast data")
        
        try await client.request(CastEndpoint.insertCastData(data.toDictionary()))
    }
    
    public func revokeAllTokens() async throws {
        logger.info("Revoking all cast tokens")
        
        try await client.request(CastEndpoint.revokeAllTokens)
    }
    
    // MARK: - Cast File Operations
    
    public func getThumbnail(fileID: FileID) async throws -> Data {
        logger.info("Getting thumbnail for file: \(fileID)")
        
        return try await client.download(CastEndpoint.getThumbnail(fileID: fileID))
    }
    
    public func getFile(fileID: FileID) async throws -> Data {
        logger.info("Getting file: \(fileID)")
        
        return try await client.download(CastEndpoint.getFile(fileID: fileID))
    }
    
    public func getDiff(sinceTime: Int64) async throws -> CastDiff {
        logger.info("Getting cast diff since: \(sinceTime)")
        
        return try await client.request(
            CastEndpoint.getDiff(sinceTime: sinceTime),
            responseType: CastDiff.self
        )
    }
    
    public func getCollection() async throws -> CastCollection {
        logger.info("Getting cast collection info")
        
        return try await client.request(
            CastEndpoint.getCollection,
            responseType: CastCollection.self
        )
    }
}