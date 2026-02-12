package io.ente.photos.screensaver.prefs

enum class PhotoSourceType {
    MEDIASTORE,
    ENTE_PUBLIC_ALBUM,
}

enum class FitMode {
    CROP,
    FIT,
}

enum class OverlayMode {
    NORMAL,
    ALTERNATE,
    DISABLE,
}

data class SaverSettings(
    val sourceType: PhotoSourceType,
    val intervalMs: Long,
    val shuffle: Boolean,
    val fitMode: FitMode,
    val enteCacheLimit: Int,
    val enteRefreshIntervalMs: Long,
    val overlayMode: OverlayMode,
)
