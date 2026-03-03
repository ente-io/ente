import XCTest
@testable import EnteCast

final class EnteCastTests: XCTestCase {
    
    func testCastFileEligibility() {
        let imageFile = CastFile(
            id: FileID(1),
            metadata: CastFileMetadata(fileType: 0, title: "image.jpg"), // Image type
            info: CastFileInfo(fileSize: 1024 * 1024), // 1MB
            file: CastFileData(decryptionHeader: "header"),
            thumbnail: CastFileData(decryptionHeader: "thumb-header"),
            key: "key",
            updationTime: 123456,
            isDeleted: false
        )
        
        XCTAssertTrue(imageFile.isImage)
        XCTAssertTrue(imageFile.isEligibleForSlideshow)
        
        let largeFile = CastFile(
            id: FileID(2),
            metadata: CastFileMetadata(fileType: 0, title: "large.jpg"),
            info: CastFileInfo(fileSize: 200 * 1024 * 1024), // 200MB - too large
            file: CastFileData(decryptionHeader: "header"),
            thumbnail: CastFileData(decryptionHeader: "thumb-header"),
            key: "key",
            updationTime: 123456,
            isDeleted: false
        )
        
        XCTAssertFalse(largeFile.isEligibleForSlideshow)
    }
    
    func testSlideConfiguration() {
        let defaultConfig = SlideConfiguration.default
        XCTAssertEqual(defaultConfig.duration, 12.0)
        XCTAssertTrue(defaultConfig.shuffle)
        
        let tvConfig = SlideConfiguration.tvOptimized
        XCTAssertTrue(tvConfig.useThumbnails)
        XCTAssertEqual(tvConfig.maxFileSize, 50 * 1024 * 1024)
    }
    
    func testCastPayload() {
        let payload = CastPayload(
            collectionID: CollectionID(123),
            collectionKey: "test-key",
            castToken: "test-token"
        )
        
        XCTAssertEqual(payload.collectionID, CollectionID(123))
        XCTAssertEqual(payload.collectionKey, "test-key")
        XCTAssertEqual(payload.castToken, "test-token")
    }
}