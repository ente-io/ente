import Foundation
import Logging

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

public class CastFileService {
    private let castGateway: CastGateway
    private let logger = Logger(label: "CastFileService")
    
    public init(castGateway: CastGateway) {
        self.castGateway = castGateway
    }
    
    // MARK: - File Discovery
    
    public func fetchAllFiles(castToken: String) async throws -> [CastFile] {
        logger.info("Fetching all cast files")
        
        var allFiles: [FileID: CastFile] = [:]
        var sinceTime: Int64 = 0
        
        while true {
            let diff = try await castGateway.getDiff(sinceTime: sinceTime)
            
            guard !diff.diff.isEmpty else { break }
            
            for change in diff.diff {
                sinceTime = max(sinceTime, change.updationTime)
                
                if change.isDeleted {
                    allFiles.removeValue(forKey: change.id)
                } else {
                    // Convert network model to our model
                    // Note: This is a simplified conversion
                    // In practice, we'd need to decrypt the file metadata
                    let castFile = CastFile(
                        id: change.id,
                        metadata: CastFileMetadata(fileType: 0, title: "File \(change.id)"), // TODO: Get real metadata
                        info: CastFileInfo(fileSize: nil),
                        file: CastFileData(decryptionHeader: ""), // TODO: Get real headers
                        thumbnail: CastFileData(decryptionHeader: ""),
                        key: "", // TODO: Get real key
                        updationTime: change.updationTime,
                        isDeleted: false
                    )
                    allFiles[change.id] = castFile
                }
            }
            
            if !diff.hasMore { break }
        }
        
        let files = Array(allFiles.values)
        logger.info("Fetched \(files.count) files")
        return files
    }
    
    // MARK: - File Download
    
    public func downloadFile(
        castFile: CastFile,
        castToken: String,
        useThumbnail: Bool = false
    ) async throws -> Data {
        logger.info("Downloading file \(castFile.id), thumbnail: \(useThumbnail)")
        
        let encryptedData: Data
        let decryptionHeader: String
        
        if useThumbnail {
            encryptedData = try await castGateway.getThumbnail(fileID: castFile.id)
            decryptionHeader = castFile.thumbnail.decryptionHeader
        } else {
            encryptedData = try await castGateway.getFile(fileID: castFile.id)
            decryptionHeader = castFile.file.decryptionHeader
        }
        
        // Decrypt the file data
        let decryptedData = try await decryptFileData(
            encryptedData: encryptedData,
            key: castFile.key,
            decryptionHeader: decryptionHeader
        )
        
        // Process the file based on its type
        return try await processFileData(decryptedData, castFile: castFile)
    }
    
    private func decryptFileData(
        encryptedData: Data,
        key: String,
        decryptionHeader: String
    ) async throws -> Data {
        do {
            logger.info("Decrypting file data: \(encryptedData.count) bytes encrypted")
            
            // Use proper stream decryption
            let decryptedData = try CryptoUtil.decryptFileData(
                encryptedData: encryptedData,
                base64Key: key,
                base64Header: decryptionHeader
            )
            
            logger.info("Successfully decrypted \(encryptedData.count) bytes to \(decryptedData.count) bytes")
            return decryptedData
        } catch {
            logger.error("Stream decryption failed: \(error)")
            throw CastError.decryptionError(error.localizedDescription)
        }
    }
    
    // MARK: - File Processing
    
    public func processFileData(_ data: Data, castFile: CastFile) async throws -> Data {
        if castFile.isImage {
            return try await processImageData(data, castFile: castFile)
        } else if castFile.isVideo {
            return try await processVideoData(data, castFile: castFile)
        } else if castFile.isLivePhoto {
            return try await processLivePhotoData(data, castFile: castFile)
        }
        
        return data
    }
    
    private func processImageData(_ data: Data, castFile: CastFile) async throws -> Data {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            throw CastError.invalidImageData
        }
        
        // Convert HEIC to JPEG for better tvOS compatibility
        if castFile.isHEIC {
            guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
                throw CastError.imageConversionFailed
            }
            return jpegData
        }
        
        return data
        #else
        return data
        #endif
    }
    
    private func processVideoData(_ data: Data, castFile: CastFile) async throws -> Data {
        // For videos, we might want to extract a thumbnail or process metadata
        // For now, return the data as-is
        return data
    }
    
    private func processLivePhotoData(_ data: Data, castFile: CastFile) async throws -> Data {
        // For live photos, extract the still image component
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            throw CastError.invalidImageData
        }
        
        // Convert to JPEG for slideshow display
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw CastError.imageConversionFailed
        }
        return jpegData
        #else
        return data
        #endif
    }
    
    // MARK: - File Filtering
    
    public func filterEligibleFiles(_ files: [CastFile], configuration: SlideConfiguration) -> [CastFile] {
        return files.filter { $0.isEligibleForSlideshow(with: configuration) }
    }
    
    public func shuffleFiles(_ files: [CastFile]) -> [CastFile] {
        return files.shuffled()
    }
}