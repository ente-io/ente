package io.ente.photos.screensaver.slideshow

import android.content.Context
import android.net.Uri
import coil.ImageLoader
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.diagnostics.redactedForLog
import io.ente.photos.screensaver.permissions.MediaPermissions
import io.ente.photos.screensaver.ente.EnteImageCache
import io.ente.photos.screensaver.photos.EntePublicAlbumPhotoSource
import io.ente.photos.screensaver.photos.MediaStorePhotoSource
import io.ente.photos.screensaver.photos.PhotoSource
import io.ente.photos.screensaver.prefs.PhotoSourceType
import io.ente.photos.screensaver.prefs.PreferencesRepository
import io.ente.photos.screensaver.ui.SlideshowView
import kotlin.coroutines.coroutineContext
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout

class SlideshowController(
    private val context: Context,
    private val scope: CoroutineScope,
    private val slideshowView: SlideshowView,
    private val imageLoader: ImageLoader,
    private val preferencesRepository: PreferencesRepository,
) {

    private var job: Job? = null

    fun start() {
        stop()
        job = scope.launch {
            run()
        }
    }

    fun stop() {
        job?.cancel()
        job = null
        slideshowView.clear()
    }

    private fun primarySource(sourceType: PhotoSourceType): PhotoSource {
        return when (sourceType) {
            PhotoSourceType.MEDIASTORE -> MediaStorePhotoSource(context)
            PhotoSourceType.ENTE_PUBLIC_ALBUM -> EntePublicAlbumPhotoSource(context)
        }
    }

    private data class QueueResult(
        val orderedUris: List<Uri>,
        val cachedCount: Int,
    )

    private fun buildQueue(
        uris: List<Uri>,
        shuffle: Boolean,
        prioritizeEnteCache: Boolean,
    ): QueueResult {
        if (uris.isEmpty()) return QueueResult(emptyList(), 0)
        if (!prioritizeEnteCache) {
            return QueueResult(if (shuffle) uris.shuffled() else uris, 0)
        }

        val cached = ArrayList<Uri>()
        val uncached = ArrayList<Uri>()
        uris.forEach { uri ->
            if (isEnteCached(uri)) {
                cached += uri
            } else {
                uncached += uri
            }
        }

        val orderedCached = if (shuffle) cached.shuffled() else cached
        val orderedUncached = if (shuffle) uncached.shuffled() else uncached
        return QueueResult(orderedCached + orderedUncached, cached.size)
    }

    private fun isEnteCached(uri: Uri): Boolean {
        if (uri.scheme != "ente") return false
        val accessToken = uri.host.orEmpty()
        val segments = uri.pathSegments
        if (accessToken.isBlank() || segments.size < 2) return false

        val kind = segments[0]
        val fileId = segments[1].toLongOrNull() ?: return false
        val cache = EnteImageCache(context.applicationContext)
        return when (kind) {
            "image" -> {
                val full = cache.imageFile(accessToken, fileId)
                val preview = cache.previewFile(accessToken, fileId)
                (full.exists() && full.length() > 0L) || (preview.exists() && preview.length() > 0L)
            }
            "thumb" -> {
                val preview = cache.previewFile(accessToken, fileId)
                preview.exists() && preview.length() > 0L
            }
            else -> false
        }
    }

    private fun entePreviewFallbackUri(uri: Uri): Uri? {
        if (uri.scheme != "ente") return null
        val accessToken = uri.host.orEmpty()
        val segments = uri.pathSegments
        if (accessToken.isBlank() || segments.size < 2) return null
        if (segments[0] != "image") return null
        val fileId = segments[1].toLongOrNull() ?: return null
        return Uri.parse("ente://$accessToken/thumb/$fileId")
    }

    private suspend fun run() {
        val settings = preferencesRepository.get()
        slideshowView.setFitMode(settings.fitMode)
        slideshowView.setOverlayMode(settings.overlayMode)

        if (
            settings.sourceType == PhotoSourceType.MEDIASTORE &&
            !MediaPermissions.hasReadImagesPermission(context)
        ) {
            slideshowView.showMessage(context.getString(R.string.missing_permission))
            return
        }

        val source = primarySource(settings.sourceType)
        val holdLoadingMessage = settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM
        val prioritizeEnteCache = settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM
        val enteRepo = if (holdLoadingMessage) {
            io.ente.photos.screensaver.ente.EntePublicAlbumRepository.get(context)
        } else {
            null
        }

        if (holdLoadingMessage) {
            slideshowView.showMessage(context.getString(R.string.ente_album_loading))
        }

        val maxItems = if (settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM) {
            settings.enteCacheLimit.coerceAtLeast(1)
        } else {
            5000
        }

        AppLog.info("Slideshow", "Loading photos from ${settings.sourceType}")
        val sourceLoadTimeoutMs = if (settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM) 60_000L else 20_000L
        val imageLoadTimeoutMs = 25_000L

        suspend fun loadPhotosWithTimeout(forceRefresh: Boolean, stage: String): List<Uri>? {
            return try {
                withTimeout(sourceLoadTimeoutMs) {
                    source.loadPhotos(maxItems = maxItems, forceRefresh = forceRefresh)
                }
            } catch (e: TimeoutCancellationException) {
                AppLog.error("Slideshow", "$stage timed out after ${sourceLoadTimeoutMs}ms", e)
                null
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                AppLog.error("Slideshow", "$stage failed", e)
                null
            }
        }

        suspend fun showNextWithTimeout(uri: Uri, transitionMs: Long): Boolean {
            return try {
                withTimeout(imageLoadTimeoutMs) {
                    slideshowView.showNext(
                        uri = uri,
                        imageLoader = imageLoader,
                        transitionMs = transitionMs,
                    )
                }
            } catch (e: TimeoutCancellationException) {
                AppLog.error(
                    "Slideshow",
                    "Image load timed out for ${uri.redactedForLog()} after ${imageLoadTimeoutMs}ms",
                    e,
                )
                false
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                AppLog.error("Slideshow", "Image load crashed for ${uri.redactedForLog()}", e)
                false
            }
        }

        var lastLoadAttemptAtMs = System.currentTimeMillis()
        var photos = loadPhotosWithTimeout(forceRefresh = false, stage = "Initial load").orEmpty()

        if (photos.isEmpty() && settings.sourceType != PhotoSourceType.ENTE_PUBLIC_ALBUM) {
            slideshowView.showMessage(context.getString(R.string.no_photos))
            return
        }

        if (photos.isNotEmpty()) {
            AppLog.info("Slideshow", "Loaded ${photos.size} photos")
            if (!holdLoadingMessage) {
                slideshowView.showMessage(null)
            }
        }

        val initialQueueResult = buildQueue(
            uris = photos,
            shuffle = settings.shuffle,
            prioritizeEnteCache = prioritizeEnteCache,
        )
        var queue: List<Uri> = initialQueueResult.orderedUris
        var cachedCountInQueue = initialQueueResult.cachedCount
        if (prioritizeEnteCache && photos.isNotEmpty()) {
            AppLog.info(
                "Slideshow",
                "Prioritized ${cachedCountInQueue}/${photos.size} cached Ente images",
            )
        }
        var lastShown: Uri? = null
        val failedUris = LinkedHashSet<Uri>()

        val intervalMs = settings.intervalMs.coerceAtLeast(1_000L)
        val loadingGraceMs = 15 * 1000L

        val refreshIntervalMs = if (settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM) {
            settings.enteRefreshIntervalMs
        } else {
            60 * 60 * 1000L
        }
        val periodicRefreshEnabled = refreshIntervalMs > 0
        val configCheckIntervalMs = 10 * 1000L
        val maxForceRefreshAttempts = 3
        var lastRefreshAtMs = System.currentTimeMillis()
        var lastConfigCheckAtMs = 0L
        var lastForceRefreshAttemptAtMs = 0L
        var pendingForceRefresh = false
        var forceRefreshAttempts = 0
        var lastConfigSignature = enteRepo?.getConfig()?.let {
            "${it.accessToken}|${it.collectionKeyB64}|${it.accessTokenJWT}"
        }

        var hasShownImage = false
        var index = 0
        var consecutiveFailures = 0
        var showingFailureMessage = false
        while (coroutineContext.isActive) {
            val now = System.currentTimeMillis()

            if (enteRepo != null && now - lastConfigCheckAtMs >= configCheckIntervalMs) {
                val signature = enteRepo.getConfig()?.let {
                    "${it.accessToken}|${it.collectionKeyB64}|${it.accessTokenJWT}"
                }
                if (signature != lastConfigSignature) {
                    lastConfigSignature = signature
                    pendingForceRefresh = true
                    forceRefreshAttempts = 0
                    AppLog.info("Slideshow", "Album config changed; forcing refresh")
                }
                lastConfigCheckAtMs = now
            }

            if (settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM) {
                val shouldPeriodicRefresh = periodicRefreshEnabled &&
                    now - lastRefreshAtMs >= refreshIntervalMs.coerceAtLeast(60_000L)
                val shouldForceRefresh = pendingForceRefresh &&
                    now - lastForceRefreshAttemptAtMs >= configCheckIntervalMs

                if (shouldPeriodicRefresh || shouldForceRefresh) {
                    if (shouldForceRefresh) {
                        lastForceRefreshAttemptAtMs = now
                        forceRefreshAttempts += 1
                    }

                    lastLoadAttemptAtMs = now
                    val refreshed = loadPhotosWithTimeout(
                        forceRefresh = shouldForceRefresh,
                        stage = if (shouldForceRefresh) "Forced refresh" else "Refresh",
                    )

                    if (!refreshed.isNullOrEmpty()) {
                        photos = refreshed
                        val refreshedQueueResult = buildQueue(
                            uris = photos,
                            shuffle = settings.shuffle,
                            prioritizeEnteCache = prioritizeEnteCache,
                        )
                        queue = refreshedQueueResult.orderedUris
                        cachedCountInQueue = refreshedQueueResult.cachedCount
                        index = 0
                        failedUris.clear()
                        if (!holdLoadingMessage || hasShownImage) {
                            slideshowView.showMessage(null)
                        }
                        pendingForceRefresh = false
                        forceRefreshAttempts = 0
                        AppLog.info("Slideshow", "Refreshed ${photos.size} photos")
                        if (prioritizeEnteCache) {
                            AppLog.info(
                                "Slideshow",
                                "Refreshed queue has ${refreshedQueueResult.cachedCount}/${photos.size} cached Ente images",
                            )
                        }
                    } else if (shouldForceRefresh) {
                        photos = emptyList()
                        queue = emptyList()
                        index = 0
                        if (forceRefreshAttempts >= maxForceRefreshAttempts) {
                            pendingForceRefresh = false
                        }
                    }
                    lastRefreshAtMs = now
                }
            }

            if (photos.isEmpty()) {
                val messageRes = when (settings.sourceType) {
                    PhotoSourceType.ENTE_PUBLIC_ALBUM -> {
                        val configured = lastConfigSignature != null
                        val isLoading = configured && (now - lastLoadAttemptAtMs) < loadingGraceMs
                        when {
                            !configured -> R.string.ente_album_not_configured
                            isLoading -> R.string.ente_album_loading
                            else -> R.string.ente_album_no_photos
                        }
                    }
                    else -> R.string.no_photos
                }
                slideshowView.showMessage(context.getString(messageRes))
                delay(1_000L)
                continue
            }

            if (index > 0 && index % queue.size == 0) {
                if (settings.shuffle) {
                    val reshuffledResult = buildQueue(
                        uris = photos,
                        shuffle = true,
                        prioritizeEnteCache = prioritizeEnteCache,
                    )
                    var reshuffled: List<Uri> = reshuffledResult.orderedUris
                    if (reshuffled.size > 1 && lastShown != null && reshuffled[0] == lastShown) {
                        reshuffled = reshuffled.drop(1) + reshuffled[0]
                    }
                    queue = reshuffled
                    cachedCountInQueue = reshuffledResult.cachedCount
                }

                if (failedUris.size < queue.size) {
                    failedUris.clear()
                }
            }

            if (failedUris.size >= queue.size) {
                if (settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM) {
                    if (cachedCountInQueue <= 0) {
                        pendingForceRefresh = true
                        lastForceRefreshAttemptAtMs = 0L
                        lastLoadAttemptAtMs = now
                        AppLog.error("Slideshow", "All images failed and no cached photos are available; forcing refresh")
                    } else {
                        AppLog.info("Slideshow", "All attempted images failed; retrying cached-first queue without forcing refresh")
                    }
                }
                failedUris.clear()
                delay(if (settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM) 250L else 1_000L)
                continue
            }

            var attempts = 0
            var uri = queue[index % queue.size]
            while (uri in failedUris && attempts < queue.size) {
                index += 1
                attempts += 1
                uri = queue[index % queue.size]
            }
            if (attempts >= queue.size) {
                delay(250L)
                continue
            }

            lastShown = uri

            val transitionMs = if (hasShownImage) 1000L else 0L
            var ok = showNextWithTimeout(
                uri = uri,
                transitionMs = transitionMs,
            )

            if (!ok) {
                val fallbackUri = entePreviewFallbackUri(uri)
                if (fallbackUri != null) {
                    AppLog.info(
                        "Slideshow",
                        "Falling back to Ente preview for ${uri.redactedForLog()}",
                    )
                    ok = showNextWithTimeout(
                        uri = fallbackUri,
                        transitionMs = transitionMs,
                    )
                }
            }

            if (ok) {
                consecutiveFailures = 0
                failedUris.remove(uri)
                if (!hasShownImage) {
                    slideshowView.showMessage(null)
                    hasShownImage = true
                    showingFailureMessage = false
                } else if (showingFailureMessage) {
                    slideshowView.showMessage(null)
                    showingFailureMessage = false
                }
                
                // Extract and display caption for Ente photos
                if (uri.scheme == "ente" && enteRepo != null) {
                    scope.launch {
                        try {
                            val accessToken = uri.host.orEmpty()
                            val segments = uri.pathSegments
                            if (accessToken.isNotBlank() && segments.size >= 2) {
                                val fileId = segments[1].toLongOrNull()
                                if (fileId != null) {
                                    val caption = enteRepo.getCaption(accessToken, fileId)
                                    slideshowView.setDescription(caption)
                                }
                            }
                        } catch (e: Exception) {
                            AppLog.error("Slideshow", "Failed to get caption for ${uri.redactedForLog()}", e)
                            slideshowView.setDescription(null)
                        }
                    }
                } else {
                    slideshowView.setDescription(null)
                }
            } else {
                consecutiveFailures += 1
                failedUris.add(uri)
                if (consecutiveFailures <= 3) {
                    AppLog.error("Slideshow", "Image load failed for ${uri.redactedForLog()}")
                }
                if (consecutiveFailures == 3) {
                    val isEnte = settings.sourceType == PhotoSourceType.ENTE_PUBLIC_ALBUM
                    val canSilentlySkip = isEnte && (hasShownImage || cachedCountInQueue > 0)

                    if (canSilentlySkip) {
                        if (showingFailureMessage) {
                            slideshowView.showMessage(null)
                            showingFailureMessage = false
                        }
                        AppLog.info("Slideshow", "Skipping failed image and continuing (offline/cache-tolerant mode)")
                    } else {
                        val messageRes = when {
                            isEnte && cachedCountInQueue <= 0 -> R.string.ente_album_no_cached_photos
                            isEnte -> R.string.ente_album_image_failed
                            else -> R.string.image_load_failed
                        }
                        slideshowView.showMessage(context.getString(messageRes))
                        showingFailureMessage = true
                    }
                }
            }
            index++
            delay(if (ok) intervalMs else 250L)
        }
    }
}
