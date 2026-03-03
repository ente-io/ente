import Foundation

public struct CastFileMetadata: Codable, Equatable {
    public let fileType: Int
    public let title: String
    public let creationTime: Int64?
    
    public init(fileType: Int, title: String, creationTime: Int64? = nil) {
        self.fileType = fileType
        self.title = title
        self.creationTime = creationTime
    }
}

public struct CastFileInfo: Codable, Equatable {
    public let fileSize: Int64?
    
    public init(fileSize: Int64?) {
        self.fileSize = fileSize
    }
}

public struct CastFileData: Codable, Equatable {
    public let decryptionHeader: String
    
    public init(decryptionHeader: String) {
        self.decryptionHeader = decryptionHeader
    }
}

public struct CastFile: Codable, Equatable {
    public let id: FileID
    public let metadata: CastFileMetadata
    public let info: CastFileInfo?
    public let file: CastFileData
    public let thumbnail: CastFileData
    public let key: String
    public let updationTime: Int64
    public let isDeleted: Bool
    
    public init(
        id: FileID,
        metadata: CastFileMetadata,
        info: CastFileInfo?,
        file: CastFileData,
        thumbnail: CastFileData,
        key: String,
        updationTime: Int64,
        isDeleted: Bool
    ) {
        self.id = id
        self.metadata = metadata
        self.info = info
        self.file = file
        self.thumbnail = thumbnail
        self.key = key
        self.updationTime = updationTime
        self.isDeleted = isDeleted
    }
    
    public var fileName: String {
        return metadata.title
    }
    
    public var fileSize: Int64 {
        return info?.fileSize ?? 0
    }
    
    // File type constants from the web app
    public var isImage: Bool {
        return metadata.fileType == 0 // FileType.image
    }
    
    public var isVideo: Bool {
        return metadata.fileType == 1 // FileType.video
    }
    
    public var isLivePhoto: Bool {
        return metadata.fileType == 2 // FileType.livePhoto
    }
    
    public func isEligibleForSlideshow(with configuration: SlideConfiguration) -> Bool {
        guard isImage || isLivePhoto || (isVideo && configuration.includeVideos) else { return false }
        
        // Check file size limits
        let maxSize: Int64 = isVideo ? configuration.maxVideoSize : configuration.maxImageSize
        guard fileSize <= maxSize else { return false }
        
        return true
    }
    
    public var fileExtension: String? {
        let title = fileName.lowercased()
        return URL(fileURLWithPath: title).pathExtension.isEmpty ? nil : URL(fileURLWithPath: title).pathExtension
    }
    
    public var isHEIC: Bool {
        return fileExtension == "heic" || fileExtension == "heif"
    }
}