// Temporary stub implementations for Ente dependencies
// TODO: Remove when actual Ente packages are integrated

import Foundation

// MARK: - EnteCore Stubs

public typealias FileID = Int
public typealias CollectionID = Int

// MARK: - EnteNetwork Stubs

public protocol CastGateway {
    func getDiff(sinceTime: Int64) async throws -> DiffResponse
    func getFile(fileID: FileID) async throws -> Data
    func getThumbnail(fileID: FileID) async throws -> Data
    func registerDevice() async throws -> DeviceRegistrationResponse
    func getCastData(deviceCode: String) async throws -> CastData
}

public struct DiffResponse: Codable {
    public let diff: [FileChange]
    public let hasMore: Bool
    
    public init(diff: [FileChange], hasMore: Bool) {
        self.diff = diff
        self.hasMore = hasMore
    }
}

public struct FileChange: Codable {
    public let id: FileID
    public let updationTime: Int64
    public let isDeleted: Bool
    
    public init(id: FileID, updationTime: Int64, isDeleted: Bool) {
        self.id = id
        self.updationTime = updationTime
        self.isDeleted = isDeleted
    }
}

public struct DeviceRegistrationResponse: Codable {
    public let code: String
    
    public init(code: String) {
        self.code = code
    }
}

public struct CastData: Codable {
    public let collectionID: Int
    public let castToken: String
    
    public init(collectionID: Int, castToken: String) {
        self.collectionID = collectionID
        self.castToken = castToken
    }
}

public enum EnteError: Error {
    case serverError(Int, String)
    case configurationError(String)
}

// Mock implementation of CastGateway
public class MockCastGateway: CastGateway {
    public init() {}
    
    public func getDiff(sinceTime: Int64) async throws -> DiffResponse {
        // Return empty diff for now
        return DiffResponse(diff: [], hasMore: false)
    }
    
    public func getFile(fileID: FileID) async throws -> Data {
        // Return mock file data
        return "Mock file data".data(using: .utf8) ?? Data()
    }
    
    public func getThumbnail(fileID: FileID) async throws -> Data {
        // Return mock thumbnail data
        return "Mock thumbnail data".data(using: .utf8) ?? Data()
    }
    
    public func registerDevice() async throws -> DeviceRegistrationResponse {
        // Generate a mock device code
        let code = String((1...6).map { _ in String(Int.random(in: 0...9)) }.joined())
        return DeviceRegistrationResponse(code: code)
    }
    
    public func getCastData(deviceCode: String) async throws -> CastData {
        // Mock implementation - throw 404 for first few calls, then return data
        throw EnteError.serverError(404, "Not found")
    }
}

// MARK: - EnteCrypto Implementation (using proper stream decryption)

import EnteCrypto

public enum CryptoUtil {
    public static func decryptChaChaBase64(data: Data, key: Data, header: Data) throws -> Data {
        // Use proper stream decryption from EnteCrypto
        return try EnteCrypto.decryptFileStream(encryptedData: data, key: key, header: header)
    }
    
    /// Decrypts file data using stream decryption with base64 encoded parameters
    /// This matches the format used by the mobile app and server
    public static func decryptFileData(
        encryptedData: Data,
        base64Key: String,
        base64Header: String
    ) throws -> Data {
        guard let keyData = Data(base64Encoded: base64Key),
              let headerData = Data(base64Encoded: base64Header) else {
            throw CastError.decryptionError("Invalid base64 key or header")
        }
        
        return try EnteCrypto.decryptFileStream(
            encryptedData: encryptedData,
            key: keyData,
            header: headerData
        )
    }
}