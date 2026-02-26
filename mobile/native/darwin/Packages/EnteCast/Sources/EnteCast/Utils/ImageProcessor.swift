import Foundation
import UniformTypeIdentifiers
import ImageIO
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

public struct ImageProcessor {
    
    // MARK: - MIME Type Detection
    
    public static func detectMIMEType(from data: Data, fileName: String = "") -> String? {
        // Try to detect from data first
        if let mimeType = detectMIMETypeFromData(data) {
            return mimeType
        }
        
        // Fallback to file extension
        return detectMIMETypeFromExtension(fileName)
    }
    
    private static func detectMIMETypeFromData(_ data: Data) -> String? {
        guard data.count >= 12 else { return nil }
        
        let bytes = data.prefix(12)
        
        // Check for common image formats
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return "image/png"
        }
        if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "image/gif"
        }
        if bytes.starts(with: [0x57, 0x45, 0x42, 0x50]) {
            return "image/webp"
        }
        // HEIF/HEIC detection
        if bytes.count >= 12 {
            let slice = bytes[4..<12]
            if slice.starts(with: [0x66, 0x74, 0x79, 0x70]) { // "ftyp"
                let subtype = bytes.suffix(4)
                if subtype.starts(with: [0x68, 0x65, 0x69, 0x63]) { // "heic"
                    return "image/heic"
                }
                if subtype.starts(with: [0x68, 0x65, 0x69, 0x66]) { // "heif"
                    return "image/heif"
                }
            }
        }
        
        return nil
    }
    
    private static func detectMIMETypeFromExtension(_ fileName: String) -> String? {
        let url = URL(fileURLWithPath: fileName)
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"
        default:
            return nil
        }
    }
    
    // MARK: - Image Processing
    
    public static func processImage(_ data: Data, fileName: String) async throws -> Data {
        guard let mimeType = detectMIMEType(from: data, fileName: fileName) else {
            throw ImageProcessorError.unsupportedFormat
        }
        
        // Handle HEIC/HEIF conversion
        if mimeType == "image/heic" || mimeType == "image/heif" {
            return try await convertHEICToJPEG(data)
        }
        
        // For other formats, return as-is for now
        return data
    }
    
    // MARK: - HEIC Conversion
    
    private static func convertHEICToJPEG(_ data: Data) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let convertedData = try convertHEICToJPEGSync(data)
                    continuation.resume(returning: convertedData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private static func convertHEICToJPEGSync(_ data: Data) throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ImageProcessorError.conversionFailed
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageProcessorError.conversionFailed
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessorError.conversionFailed
        }
        
        return mutableData as Data
    }
    
    // MARK: - Live Photo Processing
    
    public static func extractImageFromLivePhoto(_ data: Data, fileName: String) throws -> (Data, String) {
        // Live photo processing is complex and would require parsing the container format
        // For now, return the data as-is and let the system handle it
        return (data, fileName)
    }
}

// MARK: - Errors

public enum ImageProcessorError: Error, LocalizedError {
    case unsupportedFormat
    case conversionFailed
    case processingFailed
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported image format"
        case .conversionFailed:
            return "Failed to convert image format"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}