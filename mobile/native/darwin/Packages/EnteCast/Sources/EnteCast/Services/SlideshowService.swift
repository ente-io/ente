import Foundation
import Logging

public class SlideshowService: ObservableObject {
    @Published public var currentImageData: Data?
    @Published public var currentVideoData: Data?
    @Published public var currentFile: CastFile?
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    
    // Enhanced state management
    @Published public var isPlaying: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var slideLoadingProgress: Double = 0.0
    @Published public var currentSlideIndex: Int = 0
    @Published public var totalSlides: Int = 0
    
    private let fileService: CastFileService
    private let configuration: SlideConfiguration
    private let logger = Logger(label: "SlideshowService")
    
    private var slideshowTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private var currentFiles: [CastFile] = []
    private var currentIndex: Int = 0
    private var castToken: String = ""
    private var slideTimer: Timer?
    
    // Prefetching cache
    private var prefetchCache: [Int: Data] = [:]
    private let prefetchQueue = DispatchQueue(label: "slideshow.prefetch", qos: .utility)
    
    public init(fileService: CastFileService, configuration: SlideConfiguration = .tvOptimized) {
        self.fileService = fileService
        self.configuration = configuration
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Enhanced Controls
    
    public func pause() {
        logger.info("Pausing slideshow")
        slideTimer?.invalidate()
        slideTimer = nil
        
        Task { @MainActor in
            isPaused = true
            isPlaying = false
        }
    }
    
    public func resume() {
        guard !currentFiles.isEmpty else { return }
        logger.info("Resuming slideshow")
        
        Task { @MainActor in
            isPaused = false
            isPlaying = true
        }
        
        startSlideTimer()
    }
    
    public func togglePlayPause() {
        if isPaused || !isPlaying {
            resume()
        } else {
            pause()
        }
    }
    
    // MARK: - Slideshow Control
    
    public func start(castToken: String) async {
        logger.info("Starting slideshow")
        
        self.castToken = castToken
        await MainActor.run {
            isLoading = true
            error = nil
            isPlaying = false
            isPaused = false
            slideLoadingProgress = 0.0
            currentSlideIndex = 0
        }
        
        stop() // Stop any existing slideshow
        
        slideshowTask = Task {
            await runSlideshow()
        }
    }
    
    public func stop() {
        logger.info("Stopping slideshow")
        slideshowTask?.cancel()
        slideshowTask = nil
        prefetchTask?.cancel()
        prefetchTask = nil
        slideTimer?.invalidate()
        slideTimer = nil
        
        Task { @MainActor in
            isPlaying = false
            isPaused = false
        }
        
        // Clear prefetch cache
        prefetchCache.removeAll()
    }
    
    private func runSlideshow() async {
        do {
            // Fetch all files
            let allFiles = try await fileService.fetchAllFiles(castToken: castToken)
            let eligibleFiles = fileService.filterEligibleFiles(allFiles, configuration: configuration)
            
            guard !eligibleFiles.isEmpty else {
                await MainActor.run {
                    isLoading = false
                    error = "No media files found in this album"
                }
                return
            }
            
            currentFiles = configuration.shuffle ? fileService.shuffleFiles(eligibleFiles) : eligibleFiles
            currentIndex = 0
            
            await MainActor.run {
                isLoading = false
                totalSlides = currentFiles.count
                currentSlideIndex = 0
                isPlaying = true
            }
            
            // Display the first slide
            await displaySlideAtIndex(currentIndex)
            
            // Start prefetching
            startPrefetching()
            
            // Start the timer for auto-advancement
            startSlideTimer()
            
        } catch {
            logger.error("Slideshow error: \(error)")
            await MainActor.run {
                isLoading = false
                self.error = error.localizedDescription
            }
        }
    }
    
    private func displayNextSlide() async {
        guard !currentFiles.isEmpty else { return }
        
        let file = currentFiles[currentIndex]
        
        do {
            let fileData = try await fileService.downloadFile(
                castFile: file,
                castToken: castToken,
                useThumbnail: configuration.useThumbnails
            )
            
            await MainActor.run {
                currentFile = file
                
                if file.isVideo {
                    currentVideoData = fileData
                    currentImageData = nil
                } else {
                    currentImageData = fileData
                    currentVideoData = nil
                }
                
                error = nil
            }
            
            // Move to next file (loop back to start when at end)
            currentIndex = (currentIndex + 1) % currentFiles.count
            
            // If we've completed a full cycle, reshuffle if enabled
            if currentIndex == 0 && configuration.shuffle {
                currentFiles = fileService.shuffleFiles(currentFiles)
            }
            
        } catch {
            logger.error("Failed to display slide for file \(file.id): \(error)")
            // Skip this file and move to the next one
            currentIndex = (currentIndex + 1) % currentFiles.count
        }
    }
    
    // MARK: - Manual Navigation
    
    public func nextSlide() async {
        guard !currentFiles.isEmpty else { return }
        currentIndex = (currentIndex + 1) % currentFiles.count
        await displaySlideAtIndex(currentIndex, updateTimer: true)
    }
    
    public func previousSlide() async {
        guard !currentFiles.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : currentFiles.count - 1
        await displaySlideAtIndex(currentIndex, updateTimer: true)
    }
    
    // MARK: - Timer Management
    
    private func startSlideTimer() {
        guard let currentFile = currentFile else { return }
        
        slideTimer?.invalidate()
        let duration = configuration.duration(for: currentFile)
        
        slideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlaying, !self.isPaused else { return }
                await self.advanceToNextSlide()
            }
        }
    }
    
    private func advanceToNextSlide() async {
        guard !currentFiles.isEmpty else { return }
        
        currentIndex = (currentIndex + 1) % currentFiles.count
        
        // If we've completed a full cycle, reshuffle if enabled
        if currentIndex == 0 && configuration.shuffle {
            currentFiles = fileService.shuffleFiles(currentFiles)
        }
        
        await displaySlideAtIndex(currentIndex)
        
        if isPlaying && !isPaused {
            startSlideTimer()
        }
    }
    
    // MARK: - Enhanced Display Logic
    
    private func displaySlideAtIndex(_ index: Int, updateTimer: Bool = false) async {
        guard index >= 0, index < currentFiles.count else { return }
        
        let file = currentFiles[index]
        
        do {
            // Update loading state
            await MainActor.run {
                slideLoadingProgress = 0.0
                currentSlideIndex = index
            }
            
            // Check if we have prefetched data
            let fileData: Data
            if let cachedData = prefetchCache[index] {
                fileData = cachedData
                await MainActor.run { slideLoadingProgress = 1.0 }
            } else {
                fileData = try await fileService.downloadFile(
                    castFile: file,
                    castToken: castToken,
                    useThumbnail: configuration.useThumbnails
                )
                await MainActor.run { slideLoadingProgress = 1.0 }
            }
            
            await MainActor.run {
                currentFile = file
                
                if file.isVideo {
                    currentVideoData = fileData
                    currentImageData = nil
                } else {
                    currentImageData = fileData
                    currentVideoData = nil
                }
                
                error = nil
            }
            
            // Start/restart timer if needed
            if updateTimer && isPlaying && !isPaused {
                startSlideTimer()
            }
            
        } catch {
            logger.error("Failed to display slide for file \(file.id): \(error)")
            await MainActor.run {
                self.error = "Failed to load image: \(error.localizedDescription)"
                slideLoadingProgress = 0.0
            }
        }
    }
    
    // MARK: - Prefetching
    
    private func startPrefetching() {
        prefetchTask?.cancel()
        prefetchTask = Task {
            await performPrefetching()
        }
    }
    
    private func performPrefetching() async {
        let prefetchCount = min(3, currentFiles.count)
        
        for i in 1...prefetchCount {
            let prefetchIndex = (currentIndex + i) % currentFiles.count
            
            // Skip if already cached
            if prefetchCache[prefetchIndex] != nil { continue }
            
            let file = currentFiles[prefetchIndex]
            
            do {
                let fileData = try await fileService.downloadFile(
                    castFile: file,
                    castToken: castToken,
                    useThumbnail: configuration.useThumbnails
                )
                
                // Store in cache
                prefetchCache[prefetchIndex] = fileData
                
                // Clean up old cache entries (keep only 5 recent entries)
                if prefetchCache.count > 5 {
                    let oldKeys = Array(prefetchCache.keys.sorted().prefix(prefetchCache.count - 5))
                    for key in oldKeys {
                        prefetchCache.removeValue(forKey: key)
                    }
                }
                
            } catch {
                // Silently fail for prefetching - we'll try again when needed
                continue
            }
            
            // Add delay between prefetch operations to avoid overwhelming the system
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
}