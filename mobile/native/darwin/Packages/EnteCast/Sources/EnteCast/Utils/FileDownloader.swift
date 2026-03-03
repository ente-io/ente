import Foundation
import Logging

public class FileDownloader {
    private let logger = Logger(label: "FileDownloader")
    private let urlSession: URLSession
    private let cache = NSCache<NSString, NSData>()
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        setupCache()
    }
    
    private func setupCache() {
        cache.countLimit = 10 // Keep up to 10 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB total cache size
    }
    
    // MARK: - Download with Caching
    
    public func downloadWithCache(
        url: URL,
        cacheKey: String? = nil
    ) async throws -> Data {
        let key = cacheKey ?? url.absoluteString
        let cacheKey = NSString(string: key)
        
        // Check cache first
        if let cachedData = cache.object(forKey: cacheKey) {
            logger.debug("Cache hit for key: \(key)")
            return cachedData as Data
        }
        
        // Download if not cached
        logger.debug("Cache miss, downloading: \(url)")
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FileDownloaderError.downloadFailed
        }
        
        // Cache the result
        let cost = data.count
        cache.setObject(NSData(data: data), forKey: cacheKey, cost: cost)
        
        return data
    }
    
    // MARK: - Background Download
    
    public func downloadInBackground(url: URL) -> AsyncStream<DownloadProgress> {
        AsyncStream { continuation in
            let task = urlSession.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.yield(.failed(error))
                    continuation.finish()
                    return
                }
                
                guard let localURL = localURL,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    continuation.yield(.failed(FileDownloaderError.downloadFailed))
                    continuation.finish()
                    return
                }
                
                do {
                    let data = try Data(contentsOf: localURL)
                    continuation.yield(.completed(data))
                    continuation.finish()
                } catch {
                    continuation.yield(.failed(error))
                    continuation.finish()
                }
            }
            
            task.resume()
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Cache Management
    
    public func clearCache() {
        logger.info("Clearing download cache")
        cache.removeAllObjects()
    }
    
    public func removeCachedData(for key: String) {
        cache.removeObject(forKey: NSString(string: key))
    }
}

// MARK: - Download Progress

public enum DownloadProgress {
    case progress(ByteCountFormatter.CountStyle)
    case completed(Data)
    case failed(Error)
}

// MARK: - Errors

public enum FileDownloaderError: Error, LocalizedError {
    case downloadFailed
    case invalidResponse
    case cacheError
    
    public var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Download failed"
        case .invalidResponse:
            return "Invalid server response"
        case .cacheError:
            return "Cache operation failed"
        }
    }
}