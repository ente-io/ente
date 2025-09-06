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

#if canImport(UIKit)
import UIKit
#endif

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
    private let extendedPollingInterval: TimeInterval = 5.0 // 5 seconds after 1 minute
    private let pollingIntervalSwitchTime: TimeInterval = 30.0 // Switch after 30 seconds
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
    
    // NaCl sealed box decryption using libsodium
    
}

@MainActor
class RealSlideshowService: ObservableObject {
    @Published var currentImageData: Data?
    @Published var currentVideoData: Data? // Deprecated path (kept for compatibility)
    @Published var currentVideoURL: URL? // Temp file URL for AVPlayer playback
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
    
    // Enhanced slideshow features
    private var slideTimer: Timer?
    private var prefetchCache: [Int: Data] = [:]
    private var videoTempFiles: [Int: URL] = [:]
    private let slideshowConfiguration = SlideConfiguration.tvOptimized
    
    // File content caching - prevent redundant downloads
    private var fileContentCache: [Int: Data] = [:]
    private let cacheQueue = DispatchQueue(label: "fileContentCache", attributes: .concurrent)
    
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
    }
    
    func resume() {
        guard !allFiles.isEmpty else { return }
        isPaused = false
        isPlaying = true
        startSlideTimer()
    }
    
    func togglePlayPause() {
        if isPaused || !isPlaying {
            resume()
        } else {
            pause()
        }
    }
    
    func nextSlide() async {
        guard !allFiles.isEmpty else { return }
        currentFileIndex = (currentFileIndex + 1) % allFiles.count
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
    
    private func startSlideTimer() {
    guard let currentFile = currentFile else { return }
    // For video slides we rely on actual playback end rather than a fixed timer
    if currentFile.isVideo { return }
        slideTimer?.invalidate()
        let duration = slideshowConfiguration.duration(for: currentFile)
        
        slideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlaying, !self.isPaused else { return }
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
        
        currentSlideIndex = currentFileIndex
        slideLoadingProgress = 0.0
        
        // Check cache first
        if let cachedData = prefetchCache[currentFileIndex] {
            await updateCurrentSlide(with: cachedData, file: allFiles[currentFileIndex])
            slideLoadingProgress = 1.0
            return
        }
        
        // Load from network
        do {
            let file = allFiles[currentFileIndex]
            print("🔄 Loading file \(file.id): \(file.title) at index \(currentFileIndex)")
            slideLoadingProgress = 0.5
            
            let decryptedData = try await downloadAndDecryptFileContent(
                castPayload: payload,
                file: file
            )
            
            print("✅ Successfully loaded file \(file.id): \(file.title) (\(decryptedData.count) bytes)")
            
            // Cache the data
            prefetchCache[currentFileIndex] = decryptedData
            
            await updateCurrentSlide(with: decryptedData, file: file)
            slideLoadingProgress = 1.0
            
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
        currentFile = file
        
        if file.isLivePhoto {
            // Handle live photo: extract both image and video components
            do {
                let components = try extractLivePhotoComponents(from: data)
                
                // Set the image component for display
                if let imageData = components.imageData {
                    currentImageData = imageData
                    print("📸 Live photo image component loaded: \(imageData.count) bytes")
                } else {
                    print("⚠️ Live photo missing image component")
                }
                
                // Set the video component for potential playback
                if let videoData = components.videoData {
                    currentVideoData = videoData
                    print("🎥 Live photo video component loaded: \(videoData.count) bytes")
                } else {
                    print("⚠️ Live photo missing video component")
                }
                
                currentVideoURL = nil
                // Start timer for live photo (show as image with potential video interaction)
                startSlideTimer()
                
            } catch {
                print("❌ Failed to extract live photo components: \(error)")
                // Fallback to treating as regular image
                currentImageData = data
                currentVideoData = nil
                currentVideoURL = nil
                startSlideTimer()
            }
            
        } else if file.isVideo {
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
            currentImageData = nil
        } else {
            // Regular image
            currentImageData = data
            currentVideoData = nil
            currentVideoURL = nil
            // Start timer for image slide immediately
            startSlideTimer()
        }
        error = nil
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
        print("📋 Collection ID: \(castPayload.collectionID)")
        print("🔑 Collection Key: \(castPayload.collectionKey.prefix(20))...")
        print("🎫 Cast Token: [REDACTED]")
        
        // Store payload for navigation and clear any previous error
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
                    self.error = "No media files available in this collection"
                }
                return
            }
            
            print("📁 Found \(fileCount) files total")
            
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
            startSlideTimer()
            print("✅ Enhanced slideshow started with \(fileCount) slides")
            
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
            print("✅ Initial diff fetch completed - \(allFiles.count) files cached")
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
                self.lastUpdateTime = max(self.lastUpdateTime, result.latestUpdateTime)
            }
            
            hasMore = result.hasMore
            sinceTime = result.latestUpdateTime
            
            if verboseFileLogging { print("📦 Batch processed: \(result.files.count) items, hasMore: \(hasMore)") }
        }
        
        print("🏁 Initial diff fetch complete - total files cached: \(await MainActor.run { allFiles.count })")
    }
    
    private func fetchFilesBatch(castPayload: CastPayload, sinceTime: Int64) async throws -> (files: [[String: Any]], hasMore: Bool, latestUpdateTime: Int64) {
        // Use the collection ID and sinceTime in the API call
        let url = URL(string: "\(baseURL)/cast/diff?collectionID=\(castPayload.collectionID)&sinceTime=\(sinceTime)")!
        
        
        print("🆔 Fetching Collection ID: \(castPayload.collectionID)")
        
        var request = URLRequest(url: url)
        request.setValue(castPayload.castToken, forHTTPHeaderField: "X-Cast-Access-Token")
        // Include collection key in headers for server-side decryption if needed
        request.setValue(castPayload.collectionKey, forHTTPHeaderField: "X-Collection-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CastError.networkError("Invalid response")
        }
        
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw response: \(responseString.prefix(500))...")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        
        // Parse the diff response
        print("🔍 Attempting to parse JSON response...")
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let diff = json["diff"] as? [[String: Any]] else {
            print("❌ Failed to parse JSON response")
            throw CastError.networkError("Invalid JSON response")
        }
        
        let hasMore = json["hasMore"] as? Bool ?? false
        
        // Find the latest update time from this batch
        var latestUpdateTime = sinceTime
        for item in diff {
            if let updateTime = item["updationTime"] as? Int64 {
                latestUpdateTime = max(latestUpdateTime, updateTime)
            }
        }
        
        print("✅ JSON parsed: \(diff.count) items, hasMore: \(hasMore), latestTime: \(latestUpdateTime)")
        
        return (files: diff, hasMore: hasMore, latestUpdateTime: latestUpdateTime)
    }
    
    @MainActor
    private func processDiffBatch(_ items: [[String: Any]], collectionKey: String) async {
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
                    
                    // Adjust current index if necessary
                    if index <= currentFileIndex && currentFileIndex > 0 {
                        currentFileIndex -= 1
                    }
                } else {
                    print("  ⏭️ Skipping deleted file \(id) (not in list)")
                }
            } else {
                // Add or update file
                do {
                    // Only decrypt metadata here, not file content
                    if let file = try await decryptFileMetadata(item: item, collectionKey: collectionKey) {
                        // Check if file already exists
                        if let existingIndex = allFiles.firstIndex(where: { $0.id == id }) {
                            allFiles[existingIndex] = file
                            print("  🔄 Updated file: \(file.title) (ID: \(id))")
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
                throw CastError.serverError(401, "missing or invalid token")
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
        return await withUnsafeContinuation { continuation in
            cacheQueue.async {
                let cachedData = self.fileContentCache[fileID]
                continuation.resume(returning: cachedData)
            }
        }
    }
    
    private func cacheFileContent(fileID: Int, data: Data) async {
        await withUnsafeContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.fileContentCache[fileID] = data
                print("💾 Cached file \(fileID) content (\(data.count) bytes) - Cache size: \(self.fileContentCache.count) files")
                continuation.resume(returning: ())
            }
        }
    }
    
    private func clearCache() async {
        await withUnsafeContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                let clearedCount = self.fileContentCache.count
                self.fileContentCache.removeAll()
                print("🗑️ Cleared file content cache (\(clearedCount) files)")
                continuation.resume(returning: ())
            }
        }
    }
    
    private func getCacheStats() async -> (count: Int, totalSize: Int) {
        return await withUnsafeContinuation { continuation in
            cacheQueue.async {
                let count = self.fileContentCache.count
                let totalSize = self.fileContentCache.values.reduce(0) { $0 + $1.count }
                continuation.resume(returning: (count: count, totalSize: totalSize))
            }
        }
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
            if verboseDecryptionLogging { print("    🔑 File key decrypted successfully") }
        
        // Step 3: Decrypt file content using file key and decryption header
        let decryptedData = try decryptFileContent(
            encryptedData: encryptedData,
            fileKey: fileKey,
            decryptionHeader: file.fileDecryptionHeader
        )
            if verboseDecryptionLogging { print("    ✅ File content decrypted: \(decryptedData.count) bytes") }
        
        
        
        // Step 4: Cache the decrypted content
        await cacheFileContent(fileID: file.id, data: decryptedData)
        
        return decryptedData
    }

    // MARK: - Video Playback Management
    private func prepareVideoPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        // Observe duration once ready
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            self?.videoDidFinish()
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
    
    private func videoDidFinish() {
        isVideoPlaying = false
        videoPlayer?.seek(to: .zero)
        Task { @MainActor in
            await self.nextSlide()
        }
    }
    
    func stop() async {
        print("⏹️ Stopping real slideshow service...")
        
        // Clear navigation state
        await MainActor.run {
            currentFile = nil
            currentImageData = nil
            currentVideoData = nil
            error = nil
        }
        
        // Clear cache to free memory
        await clearCache()
        
        // Print final cache statistics
        let stats = await getCacheStats()
        print("📊 Final cache stats: \(stats.count) files, \(stats.totalSize) bytes")
        print("✅ Real slideshow service stopped")
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
            if verboseDecryptionLogging { print("    📄 Metadata decrypted successfully") }
            
            // Step 3: Parse decrypted metadata JSON
            let fileMetadata = try parseFileMetadata(data: metadata)
            if verboseFileLogging { print("    ✅ File metadata parsed: \(fileMetadata.title)") }
            
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
        
        print("    🔍 SecretBox: encrypted=\(encryptedKeyData.count)b, nonce=\(nonceData.count)b, key=\(collectionKeyData.count)b")
        
        // Use EnteCrypto for file key decryption (XSalsa20-Poly1305)
        do {
            let decryptedFileKey = try EnteCrypto.secretBoxOpen(encryptedKeyData, nonce: nonceData, key: collectionKeyData)
            print("    ✅ File key decrypted using EnteCrypto: \(decryptedFileKey.count) bytes")
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
import ZipFoundation

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
        
        let extractedContents = try FileManager.default.contentsOfDirectory(at: extractDirectory, includingPropertiesForKeys: nil)
        
        for fileURL in extractedContents {
            let filename = fileURL.lastPathComponent.lowercased()
            
            if filename.contains("image") {
                imageData = try Data(contentsOf: fileURL)
                imagePath = fileURL
                print("📸 Extracted live photo image: \(filename) (\(imageData?.count ?? 0) bytes)")
            } else if filename.contains("video") {
                videoData = try Data(contentsOf: fileURL)
                videoPath = fileURL
                print("🎥 Extracted live photo video: \(filename) (\(videoData?.count ?? 0) bytes)")
            } else {
                print("⚠️ Unexpected file in live photo zip: \(filename)")
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
        
        slideshowService.$currentVideoData
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentVideoData, on: self)
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
    
    func resetSession() {
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
        Task {
            await slideshowService.stop()
        }
        castSession.setState(.idle)
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
        statusMessage = "Preparing slideshow..."
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
                    handleError(slideshowService.error!)
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
        if error.contains("No media files") {
            currentView = .empty
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
        // For now, just use basic error handling since CastError is not available
        handleError("An error occurred: \(error.localizedDescription)")
    }
    
}

