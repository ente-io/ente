import Foundation

public enum CastError: Error, LocalizedError {
    case networkError(String)
    case decryptionError(String)
    case invalidImageData
    case imageConversionFailed
    case videoProcessingFailed
    case fileNotFound
    case invalidFileType
    case fileSizeTooLarge
    case deviceRegistrationFailed
    case pairingTimeout
    case invalidCastToken
    case slideshowStopped
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decryptionError(let message):
            return "Decryption error: \(message)"
        case .invalidImageData:
            return "Invalid image data"
        case .imageConversionFailed:
            return "Failed to convert image"
        case .videoProcessingFailed:
            return "Failed to process video"
        case .fileNotFound:
            return "File not found"
        case .invalidFileType:
            return "Unsupported file type"
        case .fileSizeTooLarge:
            return "File size too large"
        case .deviceRegistrationFailed:
            return "Failed to register device"
        case .pairingTimeout:
            return "Pairing timed out"
        case .invalidCastToken:
            return "Invalid cast token"
        case .slideshowStopped:
            return "Slideshow was stopped"
        }
    }
}