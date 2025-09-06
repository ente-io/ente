//
//  CastViewModel.swift
//  tv
//
//  Created by Neeraj Gupta on 28/08/25.
//

import SwiftUI
import Combine
import CryptoKit
import Foundation
import Sodium
import EnteCrypto
import AVKit
import ZIPFoundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Persistent Thread-Safe File Cache

actor ThreadSafeFileCache {
    private var cache: [Int: Data] = [:]
    private var cacheOrder: [Int] = []
    private var totalBytes: Int = 0
    private let maxBytes: Int
    private let shrinkTargetBytes: Int
    private let cacheDirectory: URL
    private let metadataURL: URL
    
    init(maxBytes: Int, shrinkTargetBytes: Int) {
        self.maxBytes = maxBytes
        self.shrinkTargetBytes = shrinkTargetBytes
        
        // Create persistent cache directory
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("EnteFileCache")
        self.metadataURL = cacheDirectory.appendingPathComponent("cache_metadata.json")
        
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load existing cache from disk
        loadCacheFromDisk()
    }
    
    func get(_ fileID: Int) -> Data? {
        // Check memory cache first
        if let data = cache[fileID] {
            return data
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(fileID).cache")
        if let data = try? Data(contentsOf: fileURL) {
            // Load into memory cache for faster future access
            cache[fileID] = data
            if !cacheOrder.contains(fileID) {
                cacheOrder.append(fileID)
            }
            totalBytes += data.count
            return data
        }
        
        return nil
    }
    
    func set(_ fileID: Int, data: Data) {
        // Remove existing data if present
        if let existingData = cache[fileID] {
            totalBytes -= existingData.count
            cacheOrder.removeAll { $0 == fileID }
        }
        
        // Add new data to memory cache
        cache[fileID] = data
        cacheOrder.append(fileID)
        totalBytes += data.count
        
        // Save to disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(fileID).cache")
        try? data.write(to: fileURL)
        
        // Enforce limits
        enforceLimits()
        
        // Save metadata
        saveCacheMetadata()
        
        print("💾 Cached file \(fileID) content (\(data.count) bytes) - Cache size: \(cache.count) files")
    }
    
    func remove(_ fileID: Int) {
        if let removedData = cache.removeValue(forKey: fileID) {
            totalBytes -= removedData.count
            cacheOrder.removeAll { $0 == fileID }
            
            // Remove from disk cache
            let fileURL = cacheDirectory.appendingPathComponent("\(fileID).cache")
            try? FileManager.default.removeItem(at: fileURL)
            
            // Save updated metadata
            saveCacheMetadata()
            
            print("🗑️ Removed cached content for file \(fileID) (\(removedData.count) bytes)")
        }
    }
    
    func clear() {
        let clearedCount = cache.count
        cache.removeAll()
        cacheOrder.removeAll()
        totalBytes = 0
        
        // Clear disk cache
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clear metadata
        try? FileManager.default.removeItem(at: metadataURL)
        
        print("🗑️ Cleared file content cache (\(clearedCount) files)")
    }
    
    func getStats() -> (count: Int, totalSize: Int) {
        return (count: cache.count, totalSize: totalBytes)
    }
    
    func getCachedFileIDs() -> [Int] {
        return Array(cache.keys) + cacheOrder.filter { !cache.keys.contains($0) }
    }
    
    private func enforceLimits() {
        guard totalBytes > maxBytes else { return }
        
        var removedBytes = 0
        while totalBytes - removedBytes > shrinkTargetBytes, let oldest = cacheOrder.first {
            cacheOrder.removeFirst()
            if let data = cache.removeValue(forKey: oldest) {
                removedBytes += data.count
                
                // Remove from disk cache
                let fileURL = cacheDirectory.appendingPathComponent("\(oldest).cache")
                try? FileManager.default.removeItem(at: fileURL)
                
                print("🧹 Evicted file \(oldest) (\(data.count) bytes) to control cache size")
            }
        }
        totalBytes -= removedBytes
        
        // Save updated metadata after eviction
        saveCacheMetadata()
        
        print("📦 Cache GC complete: now \(cache.count) files, \(totalBytes) bytes")
    }
    
    private func loadCacheFromDisk() {
        // Load metadata
        guard let metadataData = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData) else {
            print("📂 No existing cache metadata found - starting fresh")
            return
        }
        
        print("📂 Loading existing cache from disk - \(metadata.fileIDs.count) files")
        
        // Load cache order and calculate total bytes
        var loadedBytes = 0
        var validFileIDs: [Int] = []
        
        for fileID in metadata.fileIDs {
            let fileURL = cacheDirectory.appendingPathComponent("\(fileID).cache")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? Int {
                    loadedBytes += fileSize
                    validFileIDs.append(fileID)
                }
            }
        }
        
        cacheOrder = validFileIDs
        totalBytes = loadedBytes
        
        print("📂 Loaded \(validFileIDs.count) cached files (\(loadedBytes) bytes) from disk")
        
        // Clean up any invalid entries
        if validFileIDs.count != metadata.fileIDs.count {
            saveCacheMetadata()
        }
    }
    
    private func saveCacheMetadata() {
        let metadata = CacheMetadata(fileIDs: cacheOrder, totalBytes: totalBytes)
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: metadataURL)
        }
    }
}

// MARK: - Cache Metadata
struct CacheMetadata: Codable {
    let fileIDs: [Int]
    let totalBytes: Int
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let authenticationExpired = Notification.Name("authenticationExpired")
    static let slideshowRestarted = Notification.Name("slideshowRestarted")
}

// MARK: - Real Implementation with Direct Server Calls

// MARK: - Slide Configuration
struct SlideConfiguration {
    let imageDuration: TimeInterval
    let videoDuration: TimeInterval
    let useThumbnails: Bool
    let shuffle: Bool
    let maxImageSize: Int64
    let maxVideoSize: Int64
    let includeVideos: Bool
    
    // Enhanced prefetch settings
    let prefetchCount: Int
    let maxCacheSize: Int
    let prefetchDelay: TimeInterval
    let enablePrefetching: Bool
    
    init(
        imageDuration: TimeInterval = 12.0,
        videoDuration: TimeInterval = 30.0,
        useThumbnails: Bool = false,
        shuffle: Bool = true,
        maxImageSize: Int64 = 100 * 1024 * 1024, // 100MB
        maxVideoSize: Int64 = 500 * 1024 * 1024, // 500MB
        includeVideos: Bool = true,
        prefetchCount: Int = 3,
        maxCacheSize: Int = 5,
        prefetchDelay: TimeInterval = 0.5,
        enablePrefetching: Bool = true
    ) {
        self.imageDuration = imageDuration
        self.videoDuration = videoDuration
        self.useThumbnails = useThumbnails
        self.shuffle = shuffle
        self.maxImageSize = maxImageSize
        self.maxVideoSize = maxVideoSize
        self.includeVideos = includeVideos
        self.prefetchCount = prefetchCount
        self.maxCacheSize = maxCacheSize
        self.prefetchDelay = prefetchDelay
        self.enablePrefetching = enablePrefetching
    }
    
    func duration(for file: CastFile) -> TimeInterval {
        return file.isVideo ? videoDuration : imageDuration
    }
    
    static let `default` = SlideConfiguration()
    
    // TV-optimized configuration (use thumbnails for better performance)
    static let tvOptimized = SlideConfiguration(
        imageDuration: 8.0,     // Faster progression for TV viewing
        videoDuration: 25.0,
        useThumbnails: true,    // Better performance on Apple TV
        shuffle: true,
        maxImageSize: 50 * 1024 * 1024, // 50MB for TV
        maxVideoSize: 200 * 1024 * 1024, // 200MB for TV
        includeVideos: true,
        prefetchCount: 3,       // Prefetch next 3 slides
        maxCacheSize: 5,        // Keep 5 slides in cache
        prefetchDelay: 0.5,     // 500ms delay between prefetch operations
        enablePrefetching: true // Enable prefetching for smooth transitions
    )
}

// MARK: - Data Models
struct CastFile: Codable, Equatable {
    let id: Int
    let title: String
    let isVideo: Bool
    let isLivePhoto: Bool
    let encryptedKey: String
    let keyDecryptionNonce: String
    let fileDecryptionHeader: String
    let hash: String?      // BLAKE2b hash for file content verification
    
    var isImage: Bool { !isVideo && !isLivePhoto }
}

struct FileMetadata {
    let fileType: Int       // 0 = image, 1 = video, 2 = livePhoto
    let title: String       // filename with extension
    let creationTime: Int64 // microseconds since epoch
    let modificationTime: Int64
    let hash: String?       // BLAKE2b hash for file content verification
    
    var isImage: Bool { fileType == 0 }
    var isVideo: Bool { fileType == 1 }
    var isLivePhoto: Bool { fileType == 2 }
}

enum CastSessionState: Equatable {
    case idle
    case registering
    case waitingForPairing(deviceCode: String)
    case connected(CastPayload)
    case error(String)
}

struct CastPayload: Codable, Equatable {
    let collectionID: Int
    let collectionKey: String
    let castToken: String
}

struct CastDevice {
    let deviceCode: String
    let publicKey: Data
    let privateKey: Data
}

// MARK: - Server Response Models
struct DeviceRegistrationResponse: Codable {
    let deviceCode: String
}

struct CastDataResponse: Codable {
    let encCastData: String?
}

// MARK: - Errors
enum CastError: Error {
    case networkError(String)
    case serverError(Int, String?)
    case decryptionError(String)
    
    var localizedDescription: String {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown error")"
        case .decryptionError(let message):
            return "Decryption error: \(message)"
        }
    }
}

@MainActor
class CastSession: ObservableObject {
    @Published var state: CastSessionState = .idle
    @Published var isActive: Bool = false
    
    var deviceCode: String? {
        if case .waitingForPairing(let code) = state {
            return code
        }
        return nil
    }
    
    var payload: CastPayload? {
        if case .connected(let payload) = state {
            return payload
        }
        return nil
    }
    
    func setState(_ newState: CastSessionState) {
        state = newState
        isActive = !isIdle
    }
    
    private var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }
}

// MARK: - Real Cast Services

class RealCastPairingService {
    private let baseURL = "https://api.ente.io"
    private var pollingTimer: Timer?
    private var lastLoggedMessages: [String: Date] = [:]
    private let logThrottleInterval: TimeInterval = 5.0 // 5 seconds
    private var isPolling: Bool = false
    private var isFetchingPayload: Bool = false
    private var hasDeliveredPayload: Bool = false
    private var pollingStartTime: Date?
    private let initialPollingInterval: TimeInterval = 2.0 // 2 seconds initially
    private let extendedPollingInterval: TimeInterval = 5.0 // 5 seconds after 60 seconds
    private let pollingIntervalSwitchTime: TimeInterval = 60.0 // Switch after 60 seconds
    private var hasLoggedIntervalSwitch: Bool = false
    
    private func getCurrentPollingInterval() -> TimeInterval {
        guard let startTime = pollingStartTime else { return initialPollingInterval }
        let elapsed = Date().timeIntervalSince(startTime)
        let newInterval = elapsed >= pollingIntervalSwitchTime ? extendedPollingInterval : initialPollingInterval
        
        // Log when switching to extended interval for the first time
        if elapsed >= pollingIntervalSwitchTime && newInterval == extendedPollingInterval && !hasLoggedIntervalSwitch {
            print("🕐 Switched to extended polling interval (\(extendedPollingInterval)s) after \(Int(elapsed))s")
            hasLoggedIntervalSwitch = true
        }
        
        return newInterval
    }
    
    // Generate real X25519 keypair using EnteCrypto
    private func generateKeyPair() -> (publicKey: Data, privateKey: Data) {
        let keys = EnteCrypto.generateCastKeyPair()
        return (
            publicKey: Data(base64Encoded: keys.publicKey)!,
            privateKey: Data(base64Encoded: keys.privateKey)!
        )
    }
    
    func registerDevice() async throws -> CastDevice {
        print("🔑 Generating real X25519 keypair...")
        let keys = generateKeyPair()
        let publicKeyBase64 = keys.publicKey.base64EncodedString()
        
        print("📡 Registering device with Ente production server...")
        print("🌐 POST \(baseURL)/cast/device-info")
        
        let url = URL(string: "\(baseURL)/cast/device-info")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["publicKey": publicKeyBase64]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CastError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        
        let deviceResponse = try JSONDecoder().decode(DeviceRegistrationResponse.self, from: data)
        
        print("✅ Device registered! Code from server: \(deviceResponse.deviceCode)")
        
        return CastDevice(
            deviceCode: deviceResponse.deviceCode,
            publicKey: keys.publicKey,
            privateKey: keys.privateKey
        )
    }
    
    func startPolling(device: CastDevice, onPayloadReceived: @escaping (CastPayload) -> Void, onError: @escaping (Error) -> Void) {
        guard !hasDeliveredPayload else { return }
        guard !isPolling else { return }
        print("🔍 Starting real polling of Ente production server...")
        pollingTimer?.invalidate()
        isPolling = true
        pollingStartTime = Date()
        hasLoggedIntervalSwitch = false
        
        scheduleNextPoll(device: device, onPayloadReceived: onPayloadReceived, onError: onError)
    }
    
    private func scheduleNextPoll(device: CastDevice, onPayloadReceived: @escaping (CastPayload) -> Void, onError: @escaping (Error) -> Void) {
        guard isPolling && !hasDeliveredPayload else { return }
        
        let currentInterval = getCurrentPollingInterval()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: false) { [weak self] _ in
            Task {
                await self?.checkForPayload(device: device, onPayloadReceived: onPayloadReceived, onError: onError)
                // Schedule next poll after this one completes
                await MainActor.run {
                    self?.scheduleNextPoll(device: device, onPayloadReceived: onPayloadReceived, onError: onError)
                }
            }
        }
    }
    
    private func checkForPayload(device: CastDevice, onPayloadReceived: @escaping (CastPayload) -> Void, onError: @escaping (Error) -> Void) async {
        if hasDeliveredPayload { return }
        if isFetchingPayload { return }
        isFetchingPayload = true
        defer { isFetchingPayload = false }
        do {
            let url = URL(string: "\(baseURL)/cast/cast-data/\(device.deviceCode)")!
            print("📡 GET \(url.absoluteString)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CastError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode == 404 {
                // No payload available yet - this is expected
                print("⏳ No encrypted payload available yet")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
            }
            
            let castDataResponse = try JSONDecoder().decode(CastDataResponse.self, from: data)
            
            guard let encryptedData = castDataResponse.encCastData else {
                print("⏳ No encrypted payload in response yet")
                return
            }
            
            print("🔓 Received encrypted payload! Decrypting...")
            
            // Decrypt the payload using our private key
            let payload = try await decryptPayload(encryptedData: encryptedData, privateKey: device.privateKey)
            
            print("✅ Successfully decrypted cast payload!")
            hasDeliveredPayload = true
            stopPolling()
            
            await MainActor.run {
                onPayloadReceived(payload)
            }
            
        } catch {
            print("❌ Polling error: \(error)")
            await MainActor.run {
                onError(error)
            }
        }
    }
    
    private func decryptPayload(encryptedData: String, privateKey: Data) async throws -> CastPayload {
        // Generate public key from private key for sealed box decryption
        let publicKey: Data
        do {
            let curve25519PrivateKey = try CryptoKit.Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey)
            publicKey = curve25519PrivateKey.publicKey.rawRepresentation
        } catch {
            throw CastError.decryptionError("Failed to derive public key from private key: \(error)")
        }
        
        // Use EnteCrypto for cast payload decryption
        do {
            let decryptedData = try EnteCrypto.decryptCastPayload(
                encryptedPayload: encryptedData,
                recipientPublicKey: publicKey.base64EncodedString(),
                recipientPrivateKey: privateKey.base64EncodedString()
            )
            
            // Handle potential base64 preprocessing from mobile client
            let finalData: Data
            if let base64String = String(data: decryptedData, encoding: .utf8),
               let jsonData = Data(base64Encoded: base64String) {
                finalData = jsonData
            } else {
                finalData = decryptedData
            }
            
            let payload = try JSONDecoder().decode(CastPayload.self, from: finalData)
            return payload
        } catch {
            throw CastError.decryptionError("EnteCrypto cast payload decryption failed: \(error)")
        }
    }
    
    func stopPolling() {
        guard isPolling else { return }
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
        pollingStartTime = nil
        print("⏹️ Stopped polling production server")
    }
    
    func resetForNewSession() {
        print("🔄 Resetting pairing service for new session")
        stopPolling()
        hasDeliveredPayload = false
        hasLoggedIntervalSwitch = false
    }
    
    // NaCl sealed box decryption using libsodium
    
}

@MainActor
class RealSlideshowService: ObservableObject {
    @Published var currentImageData: Data?
    @Published var currentVideoData: Data? // Deprecated path (kept for compatibility)
    @Published var currentVideoURL: URL? // Temp file URL for AVPlayer playback
    @Published var livePhotoVideoData: Data? // Video component for live photos
    @Published var videoPlayer: AVPlayer?
    @Published var isVideoPlaying: Bool = false
    @Published var videoCurrentTime: Double = 0
    @Published var videoDuration: Double = 0
    @Published var currentFile: CastFile?
    @Published var error: String?
    
    // Enhanced state management
    @Published var isPlaying: Bool = false
    @Published var isPaused: Bool = false
    @Published var slideLoadingProgress: Double = 0.0
    @Published var currentSlideIndex: Int = 0
    @Published var totalSlides: Int = 0
    
    // Global file list management
    private var allFiles: [CastFile] = []
    private var currentFileIndex: Int = 0
    private var lastUpdateTime: Int64 = 0
    private var isLoadingMore: Bool = false
    private var hasCompletedInitialFetch: Bool = false
    private var storedCastPayload: CastPayload?
    
    // Periodic diff polling
    private var diffPollingTimer: Timer?
    private let diffPollingInterval: TimeInterval = 5.0  // 5 seconds
    private var isPeriodicPollingEnabled: Bool = true
    private var currentFileWasDeleted: Bool = false
    private var isStopping: Bool = false  // Flag to indicate service is being stopped
    
    // Enhanced slideshow features
    private var slideTimer: Timer?
    private var prefetchCache: [Int: Data] = [:]
    private var videoTempFiles: [Int: URL] = [:]
    private let slideshowConfiguration = SlideConfiguration.tvOptimized
    private var slideTimeRemaining: TimeInterval = 0
    private var slidePauseTime: Date?
    private var slideStartTime: Date?
    
    // File content caching - prevent redundant downloads
    private let fileCache = ThreadSafeFileCache(
        maxBytes: 4096 * 1024 * 1024, // 4GB
        shrinkTargetBytes: 2048 * 1024 * 1024 // 2GB
    )
    
    // Simplified mode: only load first file (no slideshow navigation)
    private var didDisplayFirstFile: Bool = false
    
    private let baseURL = "https://api.ente.io"
    private let castDownloadURL = "https://cast-albums.ente.io/download"
    
    // MARK: - Configuration Flags
    private let verboseFileLogging = false          // Reduces per-file spam unless true
    private let verboseDecryptionLogging = false    // Detailed size/key logs
    private let enablePreviewFallback = true        // Fetch preview image if full decrypt fails
    
    // MARK: - Enhanced Slideshow Controls
    
    func pause() {
        slideTimer?.invalidate()
        slideTimer = nil
        isPlaying = false
        isPaused = true
        
        // Calculate remaining time when pausing
        if let startTime = slideStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let totalDuration = currentFile.map { slideshowConfiguration.duration(for: $0) } ?? 0
            slideTimeRemaining = max(0, totalDuration - elapsed)
        }
        slidePauseTime = Date()
    }
    
    func resume() {
        guard !allFiles.isEmpty else { return }
        isPaused = false
        isPlaying = true
        slidePauseTime = nil
        
        // Resume with remaining time if we have it, otherwise start fresh
        if slideTimeRemaining > 0 {
            startSlideTimer(withDuration: slideTimeRemaining)
        } else {
            startSlideTimer()
        }
    }
    
    func togglePlayPause() {
        if isPaused || !isPlaying {
            resume()
        } else {
            pause()
        }
    }
    
    func nextSlide() async {
        guard !allFiles.isEmpty else { 
            // No files left - show empty state
            await MainActor.run {
                self.error = "No media files available in this album"
            }
            return 
        }
        
        // For single photo, just restart the timer without changing index
        if allFiles.count == 1 {
            print("📸 Single photo in album - restarting timer")
            if isPlaying && !isPaused {
                startSlideTimer()
            }
            return
        }
        
        // Check if current file was deleted and handle accordingly
        if currentFileWasDeleted {
            print("⏭️ Handling deleted current file")
            currentFileWasDeleted = false
            // Current index already adjusted in processDiffBatch
            if currentFileIndex >= allFiles.count {
                currentFileIndex = 0
            }
        } else {
            // Normal progression to next slide
            currentFileIndex = (currentFileIndex + 1) % allFiles.count
        }
        
        await displaySlideAtCurrentIndex()
        if isPlaying && !isPaused {
            startSlideTimer()
        }
    }
    
    func previousSlide() async {
        guard !allFiles.isEmpty else { return }
        currentFileIndex = currentFileIndex > 0 ? currentFileIndex - 1 : allFiles.count - 1
        await displaySlideAtCurrentIndex()
        if isPlaying && !isPaused {
            startSlideTimer()
        }
    }
    
    private func startSlideTimer(withDuration customDuration: TimeInterval? = nil) {
        guard let currentFile = currentFile else { return }
        // For video slides we rely on actual playback end rather than a fixed timer
        if currentFile.isVideo { 
            slideTimeRemaining = 0
            slideStartTime = nil
            return 
        }
        
        slideTimer?.invalidate()
        let duration = customDuration ?? slideshowConfiguration.duration(for: currentFile)
        slideStartTime = Date()
        slideTimeRemaining = duration
        
        // For single photo albums, we still want the timer to fire to maintain the slideshow loop
        slideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlaying, !self.isPaused else { return }
                self.slideTimeRemaining = 0
                self.slideStartTime = nil
                
                // For single photos, nextSlide will just restart the timer
                await self.nextSlide()
            }
        }
    }
    
    private func skipToNextSlide() async {
        guard !allFiles.isEmpty else { return }
        
        // Move to next slide
        currentFileIndex = (currentFileIndex + 1) % allFiles.count
        
        // If we've gone through all files and still have errors, stop the slideshow
        let maxRetries = allFiles.count
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                guard let payload = storedCastPayload else { return }
                let file = allFiles[currentFileIndex]
                
                print("🔄 Attempting to load file \(file.id): \(file.title) at index \(currentFileIndex)")
                
                let decryptedData = try await downloadAndDecryptFileContent(
                    castPayload: payload,
                    file: file
                )
                
                // Success! Update the slide
                prefetchCache[currentFileIndex] = decryptedData
                await updateCurrentSlide(with: decryptedData, file: file)
                
                await MainActor.run {
                    currentSlideIndex = currentFileIndex
                    slideLoadingProgress = 1.0
                }
                
                print("✅ Successfully loaded file \(file.id): \(file.title)")
                
                // Restart timer if playing
                if isPlaying && !isPaused {
                    startSlideTimer()
                }
                
                // Start prefetching again
                startPrefetching()
                return
                
            } catch {
                let file = allFiles[currentFileIndex]
                print("❌ Failed to load file \(file.id): \(file.title) - \(error)")
                currentFileIndex = (currentFileIndex + 1) % allFiles.count
                retryCount += 1
            }
        }
        
        // If we reach here, all files have issues
        await MainActor.run {
            self.error = "Unable to load any slides. All files may be corrupted or have decryption issues."
        }
    }
    
    private func displaySlideAtCurrentIndex() async {
        guard currentFileIndex >= 0, currentFileIndex < allFiles.count,
              let payload = storedCastPayload else { return }
        
        await MainActor.run {
            currentSlideIndex = currentFileIndex
            slideLoadingProgress = 0.0
        }
        
        // Check cache first
        if let cachedData = prefetchCache[currentFileIndex] {
            await updateCurrentSlide(with: cachedData, file: allFiles[currentFileIndex])
            await MainActor.run { slideLoadingProgress = 1.0 }
            return
        }
        
        // Load from network
        do {
            let file = allFiles[currentFileIndex]
            print("🔄 Loading file \(file.id): \(file.title) at index \(currentFileIndex)")
            await MainActor.run { slideLoadingProgress = 0.5 }
            
            let decryptedData = try await downloadAndDecryptFileContent(
                castPayload: payload,
                file: file
            )
            
            print("✅ Successfully loaded file \(file.id): \(file.title) (\(decryptedData.count) bytes)")
            
            // Cache the data
            prefetchCache[currentFileIndex] = decryptedData
            
            await updateCurrentSlide(with: decryptedData, file: file)
            await MainActor.run { slideLoadingProgress = 1.0 }
            
            // Start prefetching next few slides
            startPrefetching()
            
        } catch {
            let file = allFiles[currentFileIndex]
            print("❌ Failed to load file \(file.id): \(file.title) at index \(currentFileIndex) - \(error)")
            
            // Auto-skip problematic files and continue slideshow
            await MainActor.run {
                slideLoadingProgress = 0.0
            }
            
            // Try next slide automatically after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task {
                    await self.skipToNextSlide()
                }
            }
        }
    }
    
    @MainActor
    private func updateCurrentSlide(with data: Data, file: CastFile) {
    // Seamless transition: don't nuke existing image until replacement assigned
    let wasEmpty = error == "No media files available in this album"
    error = nil
    currentFile = file
        
        if file.isLivePhoto {
            // Handle live photo: extract image component only, store video separately
            do {
                let components = try extractLivePhotoComponents(from: data)
                
                // For live photos, only set the image component for display
                if let imageData = components.imageData {
                    currentImageData = imageData
                    print("📸 Live photo image component loaded: \(imageData.count) bytes")
                } else {
                    print("⚠️ Live photo missing image component - using original data as fallback")
                    currentImageData = data
                }
                
                // Store video component separately for long-press playback
                if let videoData = components.videoData {
                    livePhotoVideoData = videoData
                    print("🎥 Live photo video component stored: \(videoData.count) bytes")
                } else {
                    livePhotoVideoData = nil
                    print("⚠️ Live photo missing video component")
                }
                
                // Clear video properties to ensure image display
                currentVideoData = nil
                currentVideoURL = nil
                
                // Start timer for live photo (show as image)
                startSlideTimer()
                
            } catch {
                print("❌ Failed to extract live photo components: \(error)")
                // Fallback to treating as regular image
                currentImageData = data
                currentVideoData = nil
                currentVideoURL = nil
                livePhotoVideoData = nil
                startSlideTimer()
            }
            
        } else if file.isVideo {
            // Switching to video: clear image state now
            currentImageData = nil
            livePhotoVideoData = nil
            // Write decrypted data to a temp file to preserve original color space & avoid brightness shifts
            do {
                let url: URL
                if let existing = videoTempFiles[file.id] {
                    url = existing
                } else {
                    // Extract proper file extension from filename
                    let fileExtension = file.title.components(separatedBy: ".").last?.lowercased() ?? "mp4"
                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("cast_video_\(file.id)_\(UUID().uuidString).\(fileExtension)")
                    try data.write(to: tmpURL, options: .atomic)
                    videoTempFiles[file.id] = tmpURL
                    url = tmpURL
                }
                currentVideoURL = url
                currentVideoData = nil // release raw data memory
                prepareVideoPlayer(url: url)
            } catch {
                print("❌ Failed to persist video temp file: \(error)")
                currentVideoURL = nil
            }
        } else {
            // Regular image
            currentVideoData = nil
            currentVideoURL = nil
            livePhotoVideoData = nil
            currentImageData = data // assign image last for minimal black gap
            // Start timer for image slide immediately
            startSlideTimer()
        }
        error = nil
        
        // If we just transitioned from empty to having content, notify the UI
        if wasEmpty {
            print("📷 Slideshow restarted with image data - notifying UI")
            NotificationCenter.default.post(name: .slideshowRestarted, object: nil)
        }
    }
    
    private func startPrefetching() {
        Task {
            let prefetchCount = min(3, allFiles.count)
            for i in 1...prefetchCount {
                let prefetchIndex = (currentFileIndex + i) % allFiles.count
                
                // Skip if already cached
                if prefetchCache[prefetchIndex] != nil { continue }
                
                guard let payload = storedCastPayload else { continue }
                
                do {
                    let file = allFiles[prefetchIndex]
                    let data = try await downloadAndDecryptFileContent(
                        castPayload: payload,
                        file: file
                    )
                    prefetchCache[prefetchIndex] = data
                    
                    // Clean up old cache entries
                    if prefetchCache.count > 5 {
                        let oldKeys = Array(prefetchCache.keys.sorted().prefix(prefetchCache.count - 5))
                        for key in oldKeys {
                            prefetchCache.removeValue(forKey: key)
                        }
                    }
                    
                } catch {
                    // Silently skip problematic files during prefetching
                    print("⚠️ Prefetch failed for file \(prefetchIndex), will try on-demand")
                    continue
                }
                
                // Add delay between prefetch operations
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    func start(castPayload: CastPayload) async {
        print("🎬 Starting slideshow with payload:")
        
        // Enable screen saver prevention for slideshow
        ScreenSaverManager.preventScreenSaver()
        
        // Clear any expired state first, then store new payload
        await clearExpiredTokenState()
        storedCastPayload = castPayload
        await MainActor.run {
            self.error = nil
        }
        
        do {
            print("📡 Fetching files from Ente museum server...")
            
            // Initialize file list and fetch all files with pagination
            await initializeFileList(castPayload: castPayload)
            
            let fileCount = await MainActor.run { allFiles.count }
            if fileCount == 0 {
                await MainActor.run {
                    self.error = "No media files available in this album"
                }
                return
            }
            
            print("📁 Found \(fileCount) files total")
            
            // Clean up cache for files no longer in the collection
            let validFileIDs = Set(await MainActor.run { allFiles.map { $0.id } })
            await cleanupExpiredCache(validFileIDs: validFileIDs)
            
            // Initialize slideshow state
            await MainActor.run {
                self.totalSlides = fileCount
                self.currentFileIndex = 0
                self.currentSlideIndex = 0
                self.isPlaying = true
                self.isPaused = false
            }
            
            // Display first file and start slideshow
            await displaySlideAtCurrentIndex()
            
            // For single photo, ensure timer is started even if it's an image
            if fileCount == 1 {
                print("📸 Starting slideshow with single photo")
                startSlideTimer()
            } else {
                startSlideTimer()
            }
            print("✅ Enhanced slideshow started with \(fileCount) slide(s)")
            
        } catch {
            print("❌ Failed to start slideshow: \(error)")
            await MainActor.run {
                self.error = "Failed to load slideshow: \(error.localizedDescription)"
            }
        }
    }
    
    
    @MainActor
    private func initializeFileList(castPayload: CastPayload) async {
        // Check if we've already completed the initial fetch
        if hasCompletedInitialFetch && !allFiles.isEmpty {
            print("📋 Using cached file list with \(allFiles.count) files")
            return
        }
        
        // Reset state for fresh fetch
        print("📡 Performing initial diff fetch...")
        allFiles.removeAll()
        lastUpdateTime = 0
        currentFileIndex = 0
        hasCompletedInitialFetch = false
        
        // Fetch all pages until hasMore is false
        do {
            try await fetchAllFiles(castPayload: castPayload)
            // Mark as completed only after successfully fetching all pages
            hasCompletedInitialFetch = true
            // Shuffle order to randomize slideshow similar to web experience
            if !allFiles.isEmpty {
                allFiles.shuffle()
                print("🔀 Shuffled file order for slideshow")
            }
            print("✅ Initial diff fetch completed - \(allFiles.count) files cached (shuffled)")
        } catch {
            print("❌ Failed to fetch files: \(error)")
            hasCompletedInitialFetch = false // Ensure we retry on next attempt
            self.error = "Failed to load files: \(error.localizedDescription)"
        }
    }
    
    private func fetchAllFiles(castPayload: CastPayload) async throws {
        var hasMore = true
        var sinceTime = await MainActor.run { lastUpdateTime }
        
        while hasMore {
            if verboseFileLogging { print("📡 Fetching files since time: \(sinceTime)") }
            let result = try await fetchFilesBatch(castPayload: castPayload, sinceTime: sinceTime)
            
            // Process the batch on MainActor
            await processDiffBatch(result.files, collectionKey: castPayload.collectionKey)
            
            // Update pagination state on MainActor
            await MainActor.run {
                if result.latestUpdateTime > self.lastUpdateTime {
                    print("📅 Initial fetch updating lastUpdateTime: \(self.lastUpdateTime) → \(result.latestUpdateTime)")
                    self.lastUpdateTime = result.latestUpdateTime
                }
            }
            
            hasMore = result.hasMore
            sinceTime = result.latestUpdateTime
            
        }
        
        print("🏁 Initial diff fetch complete - total files cached: \(await MainActor.run { allFiles.count })")
        
        // Start periodic polling after initial fetch completes
        await MainActor.run {
            startPeriodicDiffPolling()
        }
    }
    
    private func fetchFilesBatch(castPayload: CastPayload, sinceTime: Int64) async throws -> (files: [[String: Any]], hasMore: Bool, latestUpdateTime: Int64) {
        // Use the collection ID and sinceTime in the API call
        let url = URL(string: "\(baseURL)/cast/diff?collectionID=\(castPayload.collectionID)&sinceTime=\(sinceTime)")!
        
        
        var request = URLRequest(url: url)
        request.setValue(castPayload.castToken, forHTTPHeaderField: "X-Cast-Access-Token")
        // Include collection key in headers for server-side decryption if needed
        request.setValue(castPayload.collectionKey, forHTTPHeaderField: "X-Collection-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CastError.networkError("Invalid response")
        }
        
        
        if let responseString = String(data: data, encoding: .utf8) {
            
        }
        
        guard httpResponse.statusCode == 200 else {
            // Handle 401 specially - this means token expired, need to reset to pairing
            if httpResponse.statusCode == 401 {
                await handleUnauthorizedError()
                throw CastError.serverError(401, "Authentication expired - resetting to pairing mode")
            }
            throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        
        // Parse the diff response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let diff = json["diff"] as? [[String: Any]] else {
            print("❌ Failed to parse JSON response")
            throw CastError.networkError("Invalid JSON response")
        }
        
        let hasMore = json["hasMore"] as? Bool ?? false
        
        // Find the latest update time from this batch
        var latestUpdateTime = sinceTime
        var foundAnyUpdates = false
        for item in diff {
            if let updateTime = item["updationTime"] as? Int64 {
                latestUpdateTime = max(latestUpdateTime, updateTime)
                foundAnyUpdates = true
            }
        }
        
        // If no items had updationTime, keep the original sinceTime
        if !foundAnyUpdates {
            latestUpdateTime = sinceTime
        }
        
        
        
        return (files: diff, hasMore: hasMore, latestUpdateTime: latestUpdateTime)
    }
    
    @MainActor
    private func processDiffBatch(_ items: [[String: Any]], collectionKey: String) async {
        let wasEmpty = allFiles.isEmpty
        var currentFileChanged = false
        let originalCurrentFile = currentFileIndex < allFiles.count ? allFiles[currentFileIndex] : nil
        
        for item in items {
            guard let id = item["id"] as? Int else {
                print("  ❌ No ID found in item")
                continue
            }
            
            let isDeleted = item["isDeleted"] as? Bool ?? false
            
            if isDeleted {
                // Remove file from list if it exists
                if let index = allFiles.firstIndex(where: { $0.id == id }) {
                    let removedFile = allFiles.remove(at: index)
                    print("  🗑️ Removed deleted file: \(removedFile.title) (ID: \(id))")
                    
                    // Check if deleted file was the currently playing one
                    if originalCurrentFile?.id == id {
                        currentFileWasDeleted = true
                        print("  ⚠️ Currently playing file was deleted - will handle gracefully")
                        
                        // Immediately move to next slide if current was deleted
                        Task {
                            await self.nextSlide()
                        }
                    }
                    
                    // Adjust current index if necessary
                    if index < currentFileIndex && currentFileIndex > 0 {
                        currentFileIndex -= 1
                    } else if index == currentFileIndex && currentFileIndex >= allFiles.count && !allFiles.isEmpty {
                        currentFileIndex = 0 // Wrap around to beginning
                    }
                    
                    // Remove from caches
                    prefetchCache.removeValue(forKey: id)
                    await removeCachedFileContent(fileID: id)
                    
                } else {
                    print("  ⏭️ Skipping deleted file \(id) (not in list)")
                }
            } else {
                // Add or update file
                do {
                    // Only decrypt metadata here, not file content
                    if let file = try await decryptFileMetadata(item: item, collectionKey: collectionKey) {
                        // Skip pure videos (we only want images + live photos)
                        if file.isVideo && !file.isLivePhoto {
                            if verboseFileLogging { print("  🚫 Skipping video file: \(file.title) (ID: \(id))") }
                            continue
                        }
                        // Check if file already exists
                        if let existingIndex = allFiles.firstIndex(where: { $0.id == id }) {
                            let oldFile = allFiles[existingIndex]
                            allFiles[existingIndex] = file
                            print("  🔄 Updated file: \(file.title) (ID: \(id))")
                            
                            // Check if hash changed - clear cache if so
                            if oldFile.hash != file.hash && file.hash != nil {
                                print("  🧹 Hash changed for file \(id) - clearing cache")
                                prefetchCache.removeValue(forKey: id)
                                await removeCachedFileContent(fileID: id)
                            }
                            
                            // Track if current file was modified
                            if existingIndex == currentFileIndex {
                                currentFileChanged = true
                            }
                        } else {
                            allFiles.append(file)
                            print("  ✅ Added file: \(file.title) (ID: \(id))")
                        }
                    }
                } catch {
                    print("  ❌ Error processing file \(id): \(error)")
                }
            }
        }
        
        print("📋 File list now contains \(allFiles.count) files")
        
        // Handle state transitions
        if allFiles.isEmpty {
            // Transition to empty state
            print("📭 All files removed - showing empty state")
            slideTimer?.invalidate()
            slideTimer = nil
            isPlaying = false
            isPaused = false
            currentImageData = nil
            currentVideoData = nil
            currentVideoURL = nil
            livePhotoVideoData = nil
            totalSlides = 0
            currentSlideIndex = 0
            currentFileIndex = 0
            error = "No media files available in this album"
        } else if wasEmpty {
            // Transition from empty to having files
            print("📷 Files added to empty album - starting slideshow")
            currentFileIndex = 0
            currentSlideIndex = 0
            totalSlides = allFiles.count
            
            // Restart slideshow if we have a stored payload
            if let payload = storedCastPayload {
                print("🔄 Restarting slideshow with \(allFiles.count) files")
                error = nil // Clear error first to avoid UI flicker
                
                // Display first slide and start slideshow
                Task {
                    await displaySlideAtCurrentIndex()
                    await MainActor.run {
                        self.isPlaying = true
                        self.isPaused = false
                        NotificationCenter.default.post(name: .slideshowRestarted, object: nil)
                    }
                    startSlideTimer()
                }
            }
        } else {
            // Normal update - just update count
            totalSlides = allFiles.count
            
            // Ensure current index is valid
            if currentFileIndex >= allFiles.count {
                currentFileIndex = 0
            }
            
            // If current file was modified, reload it
            if currentFileChanged && !allFiles.isEmpty {
                Task {
                    await displaySlideAtCurrentIndex()
                }
            }
        }
        
        // Clean up expired cache entries after processing batch
        let currentValidFileIDs = Set(allFiles.map { $0.id })
        Task {
            await cleanupExpiredCache(validFileIDs: currentValidFileIDs)
        }
    }
    
    // Force refresh the file list (useful for future updates)
    @MainActor
    private func refreshFileList(castPayload: CastPayload) async {
        print("🔄 Force refreshing file list...")
        hasCompletedInitialFetch = false
        await initializeFileList(castPayload: castPayload)
    }
    
    private func displayFirstFile(castPayload: CastPayload) async throws {
        guard !allFiles.isEmpty else { throw CastError.networkError("Empty file list") }
        let file = allFiles[0]
        if verboseFileLogging { print("🖼️ Displaying first file: \(file.title)") }
        await MainActor.run {
            self.currentFile = file
            self.currentImageData = nil
            self.currentVideoData = nil
            self.error = nil
        }
        do {
            let decryptedData = try await downloadAndDecryptFileContent(castPayload: castPayload, file: file)
            await MainActor.run {
                if file.isVideo { self.currentVideoData = decryptedData } else { self.currentImageData = decryptedData }
            }
        } catch {
            print("❌ Failed to load first file content: \(error)")
            if enablePreviewFallback && !file.isVideo {
                if let previewData = try? await downloadImage(castPayload: castPayload, fileID: file.id) {
                    await MainActor.run { self.currentImageData = previewData }
                    print("🖼️ Preview fallback shown for first file")
                }
            }
        }
    }
    
    private func downloadImage(castPayload: CastPayload, fileID: Int) async throws -> Data {
        // Use preview endpoint for thumbnails suitable for TV display
        let url = URL(string: "https://cast-albums.ente.io/preview/?fileID=\(fileID)")!
        
        var request = URLRequest(url: url)
        request.setValue(castPayload.castToken, forHTTPHeaderField: "X-Cast-Access-Token")
        request.setValue(castPayload.collectionKey, forHTTPHeaderField: "X-Collection-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CastError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        
    if verboseFileLogging { print("📥 Downloaded \(data.count) bytes for file \(fileID)") }
        return data
    }
    
    // MARK: - File Content Decryption Functions
    
    private func downloadEncryptedFile(castPayload: CastPayload, fileID: Int) async throws -> Data {
        // Use the file download endpoint with cast-specific headers
        let url = URL(string: "\(castDownloadURL)/?fileID=\(fileID)")!
        
        var request = URLRequest(url: url)
        // Use cast-specific headers like in the diff endpoint
        request.setValue(castPayload.castToken, forHTTPHeaderField: "X-Cast-Access-Token")
        request.setValue(castPayload.collectionKey, forHTTPHeaderField: "X-Collection-Key")
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CastError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            // Condensed error log
            let snippet = (String(data: data, encoding: .utf8) ?? "").prefix(160)
            print("❌ Download error [\(httpResponse.statusCode)] fileID=\(fileID): \(snippet)")
            if httpResponse.statusCode == 401 {
                await handleUnauthorizedError()
                throw CastError.serverError(401, "Authentication expired - resetting to pairing mode")
            } else {
                throw CastError.serverError(httpResponse.statusCode, String(snippet))
            }
        }
        if verboseFileLogging { print("📥 Successfully downloaded \(data.count) bytes for file \(fileID)") }
        return data
    }
    
    private func decryptFileContent(encryptedData: Data, fileKey: Data, decryptionHeader: String) throws -> Data {
        // Convert base64 header to data
        guard let headerBytes = Data(base64Encoded: decryptionHeader) else {
            throw CastError.decryptionError("Invalid base64 in file decryption header")
        }
        
    if verboseDecryptionLogging { print("    🔍 File decryption: encrypted=\(encryptedData.count)b, header=\(headerBytes.count)b, key=\(fileKey.count)b") }
        
        // Use EnteCrypto for XChaCha20-Poly1305 streaming decryption
        do {
            return try EnteCrypto.decryptSecretStream(encryptedData: encryptedData, key: fileKey, header: headerBytes)
        } catch {
            throw CastError.decryptionError("EnteCrypto file content decryption failed: \(error)")
        }
    }
    
    // MARK: - File Content Caching
    
    private func getCachedFileContent(fileID: Int) async -> Data? {
        return await fileCache.get(fileID)
    }
    
    private func cacheFileContent(fileID: Int, data: Data) async {
        await fileCache.set(fileID, data: data)
    }
    
    private func cleanupExpiredCache(validFileIDs: Set<Int>) async {
        let stats = await getCacheStats()
        print("🧹 Starting cache cleanup - current cache has \(stats.count) files")
        
        // Get all currently cached file IDs
        let cachedFileIDs = await fileCache.getCachedFileIDs()
        
        // Remove files that are no longer valid
        var removedCount = 0
        for cachedFileID in cachedFileIDs {
            if !validFileIDs.contains(cachedFileID) {
                await removeCachedFileContent(fileID: cachedFileID)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            let newStats = await getCacheStats()
            print("🧹 Cache cleanup complete - removed \(removedCount) expired files, now \(newStats.count) files (\(newStats.totalSize) bytes)")
        } else {
            print("🧹 Cache cleanup complete - no expired files found")
        }
    }
    
    private func clearCache() async {
        await fileCache.clear()
    }
    
    private func getCacheStats() async -> (count: Int, totalSize: Int) {
        return await fileCache.getStats()
    }

    
    private func loadAndDisplayFile(castPayload: CastPayload, file: CastFile) async throws {
        print("🖼️ Loading and displaying file: \(file.title)")
        
        // Set current file immediately for UI feedback
        await MainActor.run {
            self.currentFile = file
            // Clear previous data while loading
            self.currentImageData = nil
            self.currentVideoData = nil
        }
        
        do {
            // Download and decrypt the file content
            let decryptedData = try await downloadAndDecryptFileContent(
                castPayload: castPayload,
                file: file
            )
            
            // Update UI with decrypted content
            await MainActor.run {
                if file.isVideo {
                    self.currentVideoData = decryptedData
                    print("🎥 Video file loaded: \(decryptedData.count) bytes")
                } else {
                    self.currentImageData = decryptedData
                    print("🖼️ Image file loaded: \(decryptedData.count) bytes")
                }
            }
            
        } catch {
            print("❌ Failed to load file content: \(error)")
            
            // Show placeholder/error content
            await MainActor.run {
                self.error = "Failed to load file: \(file.title)"
                
                // Create error placeholder image
                if let errorImage = UIImage(systemName: "exclamationmark.triangle") {
                    self.currentImageData = errorImage.jpegData(compressionQuality: 0.8)
                }
            }
        }
    }
    
    // Prefetching removed in single-file mode
    
    private func downloadAndDecryptFileContent(castPayload: CastPayload, file: CastFile) async throws -> Data {
        // Check if service is stopping
        let stopping = await MainActor.run { isStopping }
        if stopping {
            throw CastError.networkError("Service is stopping")
        }
        
        // Check cache first
        if let cachedData = await getCachedFileContent(fileID: file.id) {
            if verboseFileLogging { print("💾 Using cached content for file \(file.id): \(file.title) (\(cachedData.count) bytes)") }
            return cachedData
        }
        
            if verboseFileLogging { print("🔍 Downloading and decrypting file \(file.id): \(file.title)") }
        
        // Step 1: Download encrypted file
        let encryptedData = try await downloadEncryptedFile(castPayload: castPayload, fileID: file.id)
            if verboseFileLogging { print("    📥 Downloaded \(encryptedData.count) bytes") }
        
        // Step 2: Decrypt file key using collection key
        let fileKey = try decryptFileKey(
            encryptedKey: file.encryptedKey,
            nonce: file.keyDecryptionNonce,
            collectionKey: castPayload.collectionKey
        )
            
        
        // Step 3: Decrypt file content using file key and decryption header
        let decryptedData = try decryptFileContent(
            encryptedData: encryptedData,
            fileKey: fileKey,
            decryptionHeader: file.fileDecryptionHeader
        )
            
        
        // Step 4: Cache the decrypted content
        await cacheFileContent(fileID: file.id, data: decryptedData)
        
        return decryptedData
    }

    // MARK: - Video Playback Management
    private func prepareVideoPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        // Observe duration once ready
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.videoDidFinish()
            }
        }
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = true
        videoPlayer = player
        isVideoPlaying = false
        videoCurrentTime = 0
        videoDuration = CMTimeGetSeconds(playerItem.asset.duration)
        // Auto-play
        playVideo()
        startVideoProgressUpdates()
    }
    
    private func startVideoProgressUpdates() {
        videoPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.videoCurrentTime = CMTimeGetSeconds(time)
                if let duration = self.videoPlayer?.currentItem?.duration.seconds, duration.isFinite { 
                    self.videoDuration = duration 
                }
            }
        }
    }
    
    func playVideo() {
        guard let player = videoPlayer else { return }
        player.play()
        isVideoPlaying = true
        // Ensure slideshow timer paused during video playback
        slideTimer?.invalidate()
    }
    
    func pauseVideo() {
        videoPlayer?.pause()
        isVideoPlaying = false
    }
    
    func seekVideo(by seconds: Double) {
        guard let player = videoPlayer else { return }
        let current = player.currentTime().seconds
        let target = max(0, current + seconds)
        let time = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @MainActor
    private func videoDidFinish() {
        isVideoPlaying = false
        videoPlayer?.seek(to: .zero)
        Task {
            await self.nextSlide()
        }
    }
    
    func stop() async {
        print("⏹️ Stopping real slideshow service...")
        
        // Disable screen saver prevention when stopping slideshow
        ScreenSaverManager.allowScreenSaver()
        
        // Set stopping flag to cancel ongoing operations
        await MainActor.run {
            isStopping = true
            stopPeriodicDiffPolling()
        }
        
        // Clear navigation state
        await MainActor.run {
            currentFile = nil
            currentImageData = nil
            currentVideoData = nil
            currentVideoURL = nil
            livePhotoVideoData = nil
            error = nil
        }
        
        // Clear cache to free memory only if explicitly needed
        // await clearCache() // Commented out to preserve cache across sessions
        
        // Print final cache statistics
        let stats = await getCacheStats()
        print("📊 Final cache stats: \(stats.count) files, \(stats.totalSize) bytes")
        print("✅ Real slideshow service stopped")
        
        // Reset stopping flag for next session
        await MainActor.run {
            isStopping = false
        }
    }
    
    func clearExpiredTokenState() async {
        print("🧹 Clearing expired token state from slideshow service")
        
        // Ensure screen saver prevention is disabled when clearing expired state
        ScreenSaverManager.allowScreenSaver()
        
        await MainActor.run {
            storedCastPayload = nil
            lastUpdateTime = 0
            hasCompletedInitialFetch = false
            allFiles.removeAll()
            prefetchCache.removeAll()
            // Clear any error state that might trigger empty view
            error = nil
            currentFile = nil
            currentImageData = nil
            currentVideoData = nil
            currentVideoURL = nil
            livePhotoVideoData = nil
        }
        // Don't clear cache automatically - preserve across sessions
        // await clearCache() // Only clear if needed for debugging
    }
    
    // MARK: - Periodic Diff Polling
    
    @MainActor
    private func startPeriodicDiffPolling() {
        guard isPeriodicPollingEnabled && storedCastPayload != nil else { return }
        
        stopPeriodicDiffPolling() // Stop any existing timer
        
        print("🔄 Starting periodic diff polling (every \(diffPollingInterval)s)")
        
        diffPollingTimer = Timer.scheduledTimer(withTimeInterval: diffPollingInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicDiffCheck()
            }
        }
    }
    
    @MainActor
    private func stopPeriodicDiffPolling() {
        diffPollingTimer?.invalidate()
        diffPollingTimer = nil
        print("⏹️ Stopped periodic diff polling")
    }
    
    private func performPeriodicDiffCheck() async {
        let payload = await MainActor.run { storedCastPayload }
        let isEnabled = await MainActor.run { isPeriodicPollingEnabled }
        
        guard let payload = payload, isEnabled else { return }
        
        do {
            let currentTime = await MainActor.run { lastUpdateTime }
            let result = try await fetchFilesBatch(castPayload: payload, sinceTime: currentTime)
            
            if !result.files.isEmpty {
                print("🔄 Periodic poll found \(result.files.count) changes")
                
                await processDiffBatch(result.files, collectionKey: payload.collectionKey)
                
                // Only update lastUpdateTime if we actually found items with valid updationTime
                await MainActor.run {
                    if result.latestUpdateTime > self.lastUpdateTime {
                        print("📅 Updating lastUpdateTime: \(self.lastUpdateTime) → \(result.latestUpdateTime)")
                        self.lastUpdateTime = result.latestUpdateTime
                    }
                }
            } else {
                print("🔄 Periodic poll found no changes since \(currentTime)")
            }
            
        } catch {
            if let castError = error as? CastError,
               case .serverError(401, _) = castError {
                print("🔐 401 error during periodic polling - authentication expired")
                // handleUnauthorizedError already called in fetchFilesBatch
            } else {
                print("⚠️ Periodic diff check failed: \(error)")
                // Continue polling on other errors
            }
        }
    }
    
    // MARK: - 401 Error Handling
    
    private var isHandlingAuthExpiry: Bool = false
    
    @MainActor
    private func handleUnauthorizedError() {
        // Prevent multiple concurrent auth expiry handling
        guard !isHandlingAuthExpiry else {
            print("🔐 Auth expiry already being handled - ignoring duplicate")
            return
        }
        
        isHandlingAuthExpiry = true
        print("🚨 Authentication expired - resetting to pairing mode")
        
        // CRITICAL: Stop screen saver prevention immediately before any UI transitions
        ScreenSaverManager.allowScreenSaver()
        
        // Stop all ongoing operations
        isPeriodicPollingEnabled = false
        stopPeriodicDiffPolling()
        
        // Notify the view model to reset session
        NotificationCenter.default.post(name: .authenticationExpired, object: nil)
        
        // Reset flag after a delay to allow reset to complete
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                self.isHandlingAuthExpiry = false
            }
        }
    }
    
    // MARK: - Cache Management Helpers
    
    private func removeCachedFileContent(fileID: Int) async {
        await fileCache.remove(fileID)
    }
    
    func clearAllCache() async {
        print("🧹 Manually clearing all cache")
        await fileCache.clear()
    }
    
    func getCacheInfo() async -> String {
        let stats = await getCacheStats()
        return "Cache: \(stats.count) files, \(String(format: "%.1f", Double(stats.totalSize) / 1024 / 1024)) MB"
    }
    
    
    // MARK: - File Decryption Functions
    
    private func decryptFileMetadata(item: [String: Any], collectionKey: String) async throws -> CastFile? {
        guard let id = item["id"] as? Int,
              let encryptedKey = item["encryptedKey"] as? String,
              let keyDecryptionNonce = item["keyDecryptionNonce"] as? String,
              let metadataDict = item["metadata"] as? [String: Any],
              let encryptedMetadata = metadataDict["encryptedData"] as? String,
              let metadataHeader = metadataDict["decryptionHeader"] as? String,
              let fileDict = item["file"] as? [String: Any],
              let fileDecryptionHeader = fileDict["decryptionHeader"] as? String else {
            print("    ❌ Missing required fields for file \(item["id"] ?? "unknown")")
            return nil
        }
        
        do {
            // Step 1: Decrypt file key using collection key (SecretBox)
            let fileKey = try decryptFileKey(
                encryptedKey: encryptedKey,
                nonce: keyDecryptionNonce,
                collectionKey: collectionKey
            )
            if verboseDecryptionLogging { print("    🔑 File key decrypted successfully") }
            
            // Step 2: Decrypt metadata using file key (XChaCha20-Poly1305)
            let metadata = try decryptMetadata(
                encryptedData: encryptedMetadata,
                decryptionHeader: metadataHeader,
                fileKey: fileKey
            )
            
            
            // Step 3: Parse decrypted metadata JSON
            let fileMetadata = try parseFileMetadata(data: metadata)
            
            
            // Create CastFile with decrypted metadata and decryption info
            let isVideo = fileMetadata.fileType == 1
            let isLivePhoto = fileMetadata.fileType == 2
            return CastFile(
                id: id, 
                title: fileMetadata.title, 
                isVideo: isVideo,
                isLivePhoto: isLivePhoto,
                encryptedKey: encryptedKey,
                keyDecryptionNonce: keyDecryptionNonce,
                fileDecryptionHeader: fileDecryptionHeader,
                hash: fileMetadata.hash
            )
            
        } catch {
            print("    ❌ Decryption failed: \(error)")
            throw error
        }
    }
    
    private func decryptFileKey(encryptedKey: String, nonce: String, collectionKey: String) throws -> Data {
        // Convert base64 inputs to data
        guard let encryptedKeyData = Data(base64Encoded: encryptedKey),
              let nonceData = Data(base64Encoded: nonce),
              let collectionKeyData = Data(base64Encoded: collectionKey) else {
            throw CastError.decryptionError("Invalid base64 in file key decryption")
        }
        
    
        // Use EnteCrypto for file key decryption (XSalsa20-Poly1305)
        do {
            let decryptedFileKey = try EnteCrypto.secretBoxOpen(encryptedKeyData, nonce: nonceData, key: collectionKeyData)
            return decryptedFileKey
        } catch {
            throw CastError.decryptionError("EnteCrypto SecretBox decryption failed for file key: \(error)")
        }
    }
    
    private func decryptMetadata(encryptedData: String, decryptionHeader: String, fileKey: Data) throws -> Data {
        // Convert base64 inputs to data
        guard let encryptedBytes = Data(base64Encoded: encryptedData),
              let headerBytes = Data(base64Encoded: decryptionHeader) else {
            throw CastError.decryptionError("Invalid base64 in metadata decryption")
        }
        
        print("    🔍 XChaCha20: encrypted=\(encryptedBytes.count)b, header=\(headerBytes.count)b, key=\(fileKey.count)b")
        
        // Use EnteCrypto for XChaCha20-Poly1305 streaming decryption
        // This matches the mobile app's CryptoUtil.decryptChaCha implementation
        do {
            let decryptedData = try EnteCrypto.decryptSecretStream(encryptedData: encryptedBytes, key: fileKey, header: headerBytes)
            print("    ✅ Metadata decrypted using EnteCrypto: \(decryptedData.count) bytes")
            return decryptedData
        } catch {
            throw CastError.decryptionError("EnteCrypto XChaCha20-Poly1305 decryption failed for metadata: \(error)")
        }
    }
    
    private func parseFileMetadata(data: Data) throws -> FileMetadata {
        // Parse the decrypted JSON metadata
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CastError.decryptionError("Invalid JSON in decrypted metadata")
        }
        
        let fileType = json["fileType"] as? Int ?? 0
        let title = json["title"] as? String ?? "Unknown"
        let creationTime = json["creationTime"] as? Int64 ?? 0
        let modificationTime = json["modificationTime"] as? Int64 ?? 0
        let hash = json["hash"] as? String
        
        return FileMetadata(
            fileType: fileType,
            title: title,
            creationTime: creationTime,
            modificationTime: modificationTime,
            hash: hash
        )
    }
    
    // MARK: - Hash Verification
    
    /// Computes BLAKE2b hash of data using libsodium genericHash (BLAKE2b)
    /// Uses 64-byte output to match mobile/web implementations
    private func computeBlake2bHash(data: Data) -> String? {
        return try? EnteCrypto.computeBlake2bHash(data)
    }
    
    /// Verifies that decrypted file content matches the expected hash from metadata
    /// Uses EnteCrypto for dual-format hash verification (base64 to hex conversion)
    private func verifyFileHash(decryptedData: Data, expectedHash: String?, fileName: String) -> Bool {
        let result = EnteCrypto.verifyFileHash(data: decryptedData, expectedHash: expectedHash)
        
        if !result && expectedHash != nil {
            print("❌ Hash verification FAILED for: \(fileName)")
            print("   Expected hash: \(expectedHash!.prefix(32))...")
            print("   File size: \(decryptedData.count) bytes")
        }
        
        return result
    }
}

// MARK: - Live Photo Utilities

#if os(tvOS)
func extractZipUsingFoundation(zipURL: URL, to destinationURL: URL) throws {
    do {
        try FileManager.default.unzipItem(at: zipURL, to: destinationURL)
        print("✅ Successfully extracted zip using ZipFoundation")
    } catch {
        throw CastError.decryptionError("ZipFoundation extraction failed: \(error)")
    }
}
#endif

struct LivePhotoComponents {
    let imageData: Data?
    let videoData: Data?
    let imagePath: URL?
    let videoPath: URL?
}

func extractLivePhotoComponents(from zipData: Data) throws -> LivePhotoComponents {
    let tempDirectory = FileManager.default.temporaryDirectory
    let zipURL = tempDirectory.appendingPathComponent("livephoto_\(UUID().uuidString).zip")
    let extractDirectory = tempDirectory.appendingPathComponent("livephoto_extract_\(UUID().uuidString)")
    
    defer {
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: extractDirectory)
    }
    
    try zipData.write(to: zipURL)
    try FileManager.default.createDirectory(at: extractDirectory, withIntermediateDirectories: true)
    
    var imageData: Data?
    var videoData: Data?
    var imagePath: URL?
    var videoPath: URL?
    
    do {
        // Use NSTask instead of Process for tvOS compatibility
        #if os(macOS)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        task.arguments = ["-q", zipURL.path, "-d", extractDirectory.path]
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw CastError.decryptionError("unzip command failed with status \(task.terminationStatus)")
        }
        #elseif os(tvOS)
        // For tvOS, we'll implement a simple zip reader using Foundation
        try extractZipUsingFoundation(zipURL: zipURL, to: extractDirectory)
        #endif
        
        // Enumerate all extracted files (including nested) because zips may contain a folder structure.
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        let enumerator = FileManager.default.enumerator(at: extractDirectory, includingPropertiesForKeys: resourceKeys)
        
        func isLikelyImage(_ url: URL) -> Bool {
            let ext = url.pathExtension.lowercased()
            return ["jpg", "jpeg", "png", "heic", "heif"].contains(ext)
        }
        
        func isLikelyVideo(_ url: URL) -> Bool {
            let ext = url.pathExtension.lowercased()
            return ["mov", "mp4", "m4v", "hevc"].contains(ext)
        }
        
    while let fileURL = enumerator?.nextObject() as? URL {
            // Skip directories
            if (try? fileURL.resourceValues(forKeys: Set(resourceKeys)).isDirectory) == true { continue }
            let filename = fileURL.lastPathComponent
            
            if imageData == nil && isLikelyImage(fileURL) {
                imageData = try Data(contentsOf: fileURL)
                imagePath = fileURL
                print("📸 Extracted live photo image: \(filename) (\(imageData?.count ?? 0) bytes)")
            } else if videoData == nil && isLikelyVideo(fileURL) {
                videoData = try Data(contentsOf: fileURL)
                videoPath = fileURL
                print("🎥 Extracted live photo video: \(filename) (\(videoData?.count ?? 0) bytes)")
            } else {
                // Only log unexpected files once both components missing to avoid noise
                if imageData == nil || videoData == nil {
                    print("ℹ️ Ignoring non-component file in live photo zip: \(filename)")
                }
            }
        }
        
        // Fallback heuristics: Some live photo packages may store assets without extensions or with generic names.
        if imageData == nil || videoData == nil {
            let contents = try FileManager.default.contentsOfDirectory(at: extractDirectory, includingPropertiesForKeys: nil)
            if imageData == nil {
                if let guessImage = contents.first(where: { $0.pathExtension.isEmpty }) { // pick first extension-less file as possible image
                    imageData = try? Data(contentsOf: guessImage)
                    imagePath = guessImage
                    if imageData != nil { print("📸 Heuristic image pick: \(guessImage.lastPathComponent)") }
                }
            }
            if videoData == nil {
                if let guessVideo = contents.first(where: { ["bin", "dat"].contains($0.pathExtension.lowercased()) }) {
                    videoData = try? Data(contentsOf: guessVideo)
                    videoPath = guessVideo
                    if videoData != nil { print("🎥 Heuristic video pick: \(guessVideo.lastPathComponent)") }
                }
            }
        }
        
        if imageData == nil && videoData == nil {
            throw CastError.decryptionError("No valid image or video components found in live photo zip")
        }
        
        return LivePhotoComponents(
            imageData: imageData,
            videoData: videoData,
            imagePath: imagePath,
            videoPath: videoPath
        )
        
    } catch {
        print("❌ Failed to extract live photo components: \(error)")
        throw CastError.decryptionError("Failed to extract live photo zip: \(error)")
    }
}

@MainActor
class CastViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentView: CurrentView = .connecting
    @Published var deviceCode: String = ""
    @Published var currentImageData: Data?
    @Published var currentVideoData: Data?
    @Published var currentFile: CastFile?
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let pairingService: RealCastPairingService
    private var lastLoggedMessages: [String: Date] = [:]
    private let logThrottleInterval: TimeInterval = 3.0 // 3 seconds
    private let castSession: CastSession
    
    // MARK: - Public Properties  
    public let slideshowService: RealSlideshowService
    
    enum CurrentView {
        case pairing
        case connecting
        case slideshow
        case error
        case empty
    }
    
    init() {
        print("🚀 Initializing with REAL Ente production server calls!")
        
        self.castSession = CastSession()
        self.pairingService = RealCastPairingService()
        self.slideshowService = RealSlideshowService()
        
        setupBindings()
        
        // Auto-start cast session on app launch (like web implementation)
        startCastSession()
    }
    
    private func setupBindings() {
        // Bind to cast session state changes
        castSession.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        // Bind to slideshow service updates
        slideshowService.$currentImageData
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentImageData, on: self)
            .store(in: &cancellables)
        // Auto-transition once first image arrives (covers single-image albums and empty-to-populated)
        slideshowService.$currentImageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if data != nil && (self.currentView == .connecting || self.currentView == .empty) {
                    self.currentView = .slideshow
                    self.statusMessage = ""
                    self.isLoading = false
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
        
        slideshowService.$currentVideoData
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentVideoData, on: self)
            .store(in: &cancellables)
        slideshowService.$currentVideoData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if data != nil && (self.currentView == .connecting || self.currentView == .empty) {
                    self.currentView = .slideshow
                    self.statusMessage = ""
                    self.isLoading = false
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
        
        slideshowService.$currentFile
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentFile, on: self)
            .store(in: &cancellables)
        
        slideshowService.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleSlideshowError(error)
            }
            .store(in: &cancellables)
        
        // Listen for authentication expired notifications
        NotificationCenter.default.publisher(for: .authenticationExpired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleAuthenticationExpired()
            }
            .store(in: &cancellables)
        
        // Listen for slideshow restarted notifications
        NotificationCenter.default.publisher(for: .slideshowRestarted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSlideshowRestarted()
            }
            .store(in: &cancellables)
        
        // Listen for app lifecycle events to manage screen saver prevention
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                ScreenSaverManager.allowScreenSaver()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.currentView == .slideshow {
                    ScreenSaverManager.preventScreenSaver()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startCastSession() {
        castSession.setState(.registering)
        currentView = .connecting
        isLoading = true
        statusMessage = "Registering device..."
        
        Task {
            do {
                // Register device with the server
                let device = try await pairingService.registerDevice()
                
                await MainActor.run {
                    deviceCode = device.deviceCode
                    castSession.setState(.waitingForPairing(deviceCode: device.deviceCode))
                    currentView = .pairing
                    statusMessage = "Waiting for connection..."
                    isLoading = false
                }
                
                // Start polling for payload
                pairingService.startPolling(
                    device: device,
                    onPayloadReceived: { [weak self] payload in
                        Task { @MainActor in
                            self?.handlePayloadReceived(payload)
                        }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor in
                            self?.handleNetworkError(error)
                        }
                    }
                )
                
            } catch {
                handleNetworkError(error)
            }
        }
    }
    
    func resetSession() async {
        print("🔄 Resetting cast session...")
        
        // Ensure screen saver prevention is disabled during reset
        ScreenSaverManager.allowScreenSaver()
        
        currentView = .connecting
        deviceCode = ""
        currentImageData = nil
        currentVideoData = nil
        currentFile = nil
        statusMessage = ""
        isLoading = false
        errorMessage = nil
        
        // Clean up services
        pairingService.stopPolling()
        await slideshowService.stop()
        castSession.setState(.idle)
        print("✅ Cast session reset complete")
    }
    
    private func handlePayloadReceived(_ payload: CastPayload) {
        // Idempotency: if we're already connected with same payload, skip
        if case .connected(let existing) = castSession.state, existing == payload {
            return
        }
        print("🎉 Cast payload received successfully!")
        
        // Update cast session with the payload
        castSession.setState(.connected(payload))
        currentView = .connecting
        statusMessage = ""
        isLoading = true
        
        // Stop polling once we receive payload
    // pairingService.stopPolling() // redundant; pairing service already stops itself when delivering payload
        
        // Start the slideshow with the full payload
        Task {
            // Add a small delay to prevent flickering from rapid state changes
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await slideshowService.start(castPayload: payload)
            
            // Additional delay to ensure slideshow is properly loaded
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                let hasError = slideshowService.error != nil && !slideshowService.error!.isEmpty
                
                if hasError {
                    handleSlideshowError(slideshowService.error!)
                } else {
                    currentView = .slideshow
                    statusMessage = ""
                    isLoading = false
                }
            }
        }
    }
    
    func retryOperation() {
        errorMessage = nil
        
        switch currentView {
        case .error:
            startCastSession()
        default:
            break
        }
    }
    
    // MARK: - Slideshow Navigation
    
    func nextSlide() {
        guard currentView == .slideshow else { return }
        
        Task {
            await slideshowService.nextSlide()
        }
    }
    
    func previousSlide() {
        guard currentView == .slideshow else { return }
        
        Task {
            await slideshowService.previousSlide()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleStateChange(_ state: CastSessionState) {
        switch state {
        case .idle:
            currentView = .connecting
            
        case .registering:
            currentView = .connecting
            statusMessage = "Registering device..."
            isLoading = true
            
        case .waitingForPairing(let code):
            deviceCode = code
            currentView = .pairing
            statusMessage = "Waiting for connection..."
            isLoading = false
            
        case .connected(let payload):
            handlePayloadReceived(payload)
            
        case .error(let message):
            handleError(message)
        }
    }
    
    
    private func handleSlideshowError(_ error: String) {
        // Prevent stale slideshow errors from a previous (expired) session
        // from overriding the fresh pairing code UI. Only react to slideshow
        // errors once we are actually in a connected/slideshow flow.
        // Exception: Allow empty state errors even during connecting
        let isEmptyStateError = error.contains("No media files") ||
            error.contains("available in this album") ||
            error.contains("available in this collection") ||
            error.contains("Empty file list")
        
        if (currentView == .pairing || currentView == .connecting) && !isEmptyStateError {
            // Ignore slideshow-originating errors during pairing / reconnection, except empty state
            return
        }
        
        if isEmptyStateError {
            currentView = .empty
            statusMessage = ""
            isLoading = false
        } else {
            handleError(error)
        }
    }
    
    
    private func handleError(_ message: String) {
        print("❌ Cast Error: \(message)")
        currentView = .error
        errorMessage = message
        isLoading = false
        statusMessage = ""
        castSession.setState(.error(message))
    }
    
    private func handleNetworkError(_ error: Error) {
        // Show error immediately
        handleError("An error occurred: \(error.localizedDescription)")
        
        // Wait 5 seconds then reset state for new device registration
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await MainActor.run {
                // Reset to start new device registration
                startCastSession()
            }
        }
    }
    
    private func handleAuthenticationExpired() {
        print("🔐 Authentication expired notification received - clearing all state and restarting")
        Task {
            await resetSession()
            // Clear all in-memory token state in slideshow service
            await slideshowService.clearExpiredTokenState()
            // Reset pairing service to allow fresh polling
            pairingService.resetForNewSession()
            
            // Ensure we're in a clean state before starting new session
            await MainActor.run {
                currentView = .connecting
                errorMessage = nil
                statusMessage = "Starting fresh session..."
                isLoading = true
            }
            
            // Generate fresh device code for new pairing
            startCastSession()
        }
    }
    
    private func handleSlideshowRestarted() {
        print("🎬 Slideshow restarted notification received")
        // Wait for image data to be available before transitioning
        // The binding will handle the transition when data arrives
        statusMessage = ""
        isLoading = false
        errorMessage = nil
        
        // Only transition if we already have image data
        if slideshowService.currentImageData != nil || slideshowService.currentVideoData != nil {
            print("🎬 Image/video data available - transitioning to slideshow view")
            currentView = .slideshow
        } else {
            print("⏳ Waiting for image data before transitioning to slideshow view")
        }
    }
    
}

