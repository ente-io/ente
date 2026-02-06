import Foundation

public struct SlideConfiguration {
    public let imageDuration: TimeInterval
    public let videoDuration: TimeInterval
    public let useThumbnails: Bool
    public let shuffle: Bool
    public let maxImageSize: Int64
    public let maxVideoSize: Int64
    public let includeVideos: Bool
    
    // Enhanced prefetch settings
    public let prefetchCount: Int
    public let maxCacheSize: Int
    public let prefetchDelay: TimeInterval
    public let enablePrefetching: Bool
    
    public init(
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
    
    public func duration(for file: CastFile) -> TimeInterval {
        return file.isVideo ? videoDuration : imageDuration
    }
    
    public static let `default` = SlideConfiguration()
    
    // TV-optimized configuration (use thumbnails for better performance)
    public static let tvOptimized = SlideConfiguration(
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