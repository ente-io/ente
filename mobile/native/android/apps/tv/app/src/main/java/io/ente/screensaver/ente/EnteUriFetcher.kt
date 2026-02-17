package io.ente.photos.screensaver.ente

import android.content.Context
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.os.Build
import androidx.exifinterface.media.ExifInterface
import coil.ImageLoader
import coil.decode.DataSource
import coil.fetch.FetchResult
import coil.fetch.Fetcher
import coil.fetch.SourceResult
import coil.request.Options
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.imageloading.ImageFormatClassifier
import io.ente.photos.screensaver.prefs.PreferencesRepository
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.max
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path.Companion.toOkioPath

class EnteUriFetcher(
    private val appContext: Context,
    private val uri: Uri,
) : Fetcher {

    private val maxImageDimension = 4096
    private val fullImageRetryDelaysMs = longArrayOf(350L, 900L, 1800L)
    private val previewRetryDelaysMs = longArrayOf(300L, 900L)

    override suspend fun fetch(): FetchResult {
        val accessToken = uri.host.orEmpty()
        val segments = uri.pathSegments
        if (accessToken.isBlank() || segments.size < 2) {
            throw IllegalArgumentException("Invalid Ente URI: $uri")
        }

        val kind = segments[0]
        val fileId = segments[1].toLongOrNull() ?: throw IllegalArgumentException("Invalid file id")
        val useFullImage = when (kind) {
            "image" -> true
            "thumb" -> false
            else -> throw IllegalArgumentException("Unsupported Ente URI kind: $kind")
        }

        val repo = EntePublicAlbumRepository.get(appContext)
        val cache = EnteImageCache(appContext)
        val settings = PreferencesRepository(appContext).get()
        val cacheLimit = settings.enteCacheLimit.coerceAtLeast(5)

        val imageCachedFile = cache.imageFile(accessToken, fileId)
        val imageMetaFile = cache.imageMetaFile(accessToken, fileId)
        val previewCachedFile = cache.previewFile(accessToken, fileId)
        val previewMetaFile = cache.previewMetaFile(accessToken, fileId)

        val cachedFile = if (useFullImage) imageCachedFile else previewCachedFile
        val metaFile = if (useFullImage) imageMetaFile else previewMetaFile
        val hasCachedFile = cachedFile.exists() && cachedFile.length() > 0

        return try {
            val record = repo.getFileRecord(accessToken, fileId)
            if (hasCachedFile) {
                if (record == null) {
                    AppLog.error("Ente", "Missing file record for cached file $fileId")
                    touchCacheFile(cachedFile)
                    return fileResult(cachedFile, DataSource.DISK, detectMimeFromFile(cachedFile))
                }
                if (!metaFile.exists() && record.updationTime > 0L) {
                    cache.writeUpdateTime(metaFile, record.updationTime)
                }
                if (isCacheFresh(record, cachedFile, metaFile, cache)) {
                    touchCacheFile(cachedFile)
                    return fileResult(cachedFile, DataSource.DISK, detectMimeFromFile(cachedFile))
                }
            }

            val resolvedRecord = record ?: throw IllegalStateException("Missing file record (refresh required)")
            val collectionKeyB64 = repo.getCollectionKeyB64(accessToken)
                ?: throw IllegalStateException("Missing album key")

            val fileKey = EnteCrypto.decryptBoxKey(
                encryptedKeyB64 = resolvedRecord.encryptedKey,
                keyDecryptionNonceB64 = resolvedRecord.keyDecryptionNonce,
                collectionKeyB64 = collectionKeyB64,
            )

            val decryptedBytes = if (useFullImage) {
                loadAndDecryptFullImage(
                    repo = repo,
                    accessToken = accessToken,
                    fileId = fileId,
                    record = resolvedRecord,
                    fileKey = fileKey,
                )
            } else {
                loadAndDecryptPreview(
                    repo = repo,
                    accessToken = accessToken,
                    fileId = fileId,
                    record = resolvedRecord,
                    fileKey = fileKey,
                )
            }

            AppLog.info(
                "Ente",
                "Decrypted ${if (useFullImage) "full" else "preview"} bytes for file $fileId (${decryptedBytes.size} bytes)",
            )

            val (processedBytes, responseMimeType) = if (useFullImage) {
                val info = inspectImage(decryptedBytes)
                val originalMime = resolveMime(info?.mime, decryptedBytes)
                val transcoded = maybeTranscodeImage(decryptedBytes, info)
                when {
                    transcoded != null -> {
                        val mime = if (transcoded !== decryptedBytes) "image/jpeg" else originalMime
                        if (transcoded === decryptedBytes) {
                            AppLog.info("Ente", "Using original full bytes for file $fileId (${originalMime ?: "unknown mime"})")
                        } else {
                            AppLog.info(
                                "Ente",
                                "Transcoded full bytes for file $fileId (${decryptedBytes.size} -> ${transcoded.size} bytes, ${originalMime ?: "unknown mime"} -> image/jpeg)",
                            )
                        }
                        Pair(transcoded, mime)
                    }

                    canKeepOriginalBytes(info, originalMime) -> {
                        AppLog.info("Ente", "Keeping original bytes for file $fileId (${originalMime ?: "unknown mime"})")
                        Pair(decryptedBytes, originalMime)
                    }

                    else -> {
                        val unsupported = isLikelyUnsupported(info, originalMime)
                        if (unsupported) {
                            repo.updateFileType(accessToken, fileId, -1)
                        }
                        throw IllegalStateException(if (unsupported) "Unsupported image" else "Image decode failed")
                    }
                }
            } else {
                val previewMime = resolveMime(null, decryptedBytes)
                AppLog.info("Ente", "Using preview bytes for file $fileId (${previewMime ?: "unknown mime"})")
                Pair(decryptedBytes, previewMime)
            }

            withContext(Dispatchers.IO) {
                cache.ensureDirs(cachedFile)
                val tmp = File(cachedFile.parentFile, cachedFile.name + ".tmp")
                tmp.writeBytes(processedBytes)
                if (!tmp.renameTo(cachedFile)) {
                    tmp.copyTo(cachedFile, overwrite = true)
                    tmp.delete()
                }
                if (resolvedRecord.updationTime > 0L) {
                    cache.writeUpdateTime(metaFile, resolvedRecord.updationTime)
                }
                touchCacheFile(cachedFile)
                cache.prune(accessToken, maxFiles = cacheLimit)
            }

            AppLog.info(
                "Ente",
                "Stored ${if (useFullImage) "image" else "preview"} file $fileId in cache (${processedBytes.size} bytes, mime=${responseMimeType ?: "unknown"})",
            )

            fileResult(cachedFile, DataSource.NETWORK, responseMimeType)
        } catch (e: Exception) {
            if (e is CancellationException) throw e

            val label = if (useFullImage) "image" else "preview"
            AppLog.error("Ente", "${label} load failed for file $fileId", e)
            if (cachedFile.exists() && cachedFile.length() > 0) {
                AppLog.info("Ente", "Using cached $label for file $fileId after error")
                touchCacheFile(cachedFile)
                return fileResult(cachedFile, DataSource.DISK, detectMimeFromFile(cachedFile))
            }
            AppLog.error("Ente", "No cached $label available for file $fileId after error")
            throw e
        }
    }

    private fun fileResult(file: File, source: DataSource, mimeType: String? = null): FetchResult {
        val imageSource = coil.decode.ImageSource(
            file.toOkioPath(),
            FileSystem.SYSTEM,
            null,
            null,
        )
        return SourceResult(
            source = imageSource,
            mimeType = mimeType,
            dataSource = source,
        )
    }

    private suspend fun loadAndDecryptFullImage(
        repo: EntePublicAlbumRepository,
        accessToken: String,
        fileId: Long,
        record: EnteFileRecord,
        fileKey: ByteArray,
    ): ByteArray {
        val header = record.fileDecryptionHeader
        if (header.isBlank()) {
            throw IllegalStateException("Missing file decryption header")
        }

        val data = downloadFileWithRetry(
            repo = repo,
            accessToken = accessToken,
            fileId = fileId,
        )

        return tryDecryptFullData(
            repo = repo,
            accessToken = accessToken,
            fileId = fileId,
            fileKey = fileKey,
            encryptedData = data,
            decryptionHeaderB64 = header,
            allowMetadataRefreshRetry = true,
        )
    }

    private suspend fun tryDecryptFullData(
        repo: EntePublicAlbumRepository,
        accessToken: String,
        fileId: Long,
        fileKey: ByteArray,
        encryptedData: ByteArray,
        decryptionHeaderB64: String,
        allowMetadataRefreshRetry: Boolean,
    ): ByteArray {
        return try {
            EnteCrypto.decryptBlobBytes(
                encryptedData = encryptedData,
                decryptionHeaderB64 = decryptionHeaderB64,
                key = fileKey,
            )
        } catch (e: Exception) {
            if (e is CancellationException) throw e

            val payloadMime = ImageFormatClassifier.sniffMime(encryptedData)
            AppLog.error(
                "Ente",
                "Full decrypt failed for file $fileId (encryptedBytes=${encryptedData.size}, headerLen=${decryptionHeaderB64.length}, payloadMime=${payloadMime ?: "none"})",
                e,
            )

            if (!allowMetadataRefreshRetry || !isRetriableDecryptError(e)) {
                throw e
            }

            AppLog.info("Ente", "Refreshing metadata and retrying full decrypt for file $fileId")
            repo.refreshIfNeeded(force = true, refreshIntervalMs = 0L)

            val refreshedRecord = repo.getFileRecord(accessToken, fileId) ?: throw e
            val refreshedCollectionKey = repo.getCollectionKeyB64(accessToken) ?: throw e
            val refreshedHeader = refreshedRecord.fileDecryptionHeader
            if (refreshedHeader.isBlank()) {
                throw e
            }

            val refreshedKey = EnteCrypto.decryptBoxKey(
                encryptedKeyB64 = refreshedRecord.encryptedKey,
                keyDecryptionNonceB64 = refreshedRecord.keyDecryptionNonce,
                collectionKeyB64 = refreshedCollectionKey,
            )

            val refreshedEncryptedData = downloadFileWithRetry(
                repo = repo,
                accessToken = accessToken,
                fileId = fileId,
            )

            return tryDecryptFullData(
                repo = repo,
                accessToken = accessToken,
                fileId = fileId,
                fileKey = refreshedKey,
                encryptedData = refreshedEncryptedData,
                decryptionHeaderB64 = refreshedHeader,
                allowMetadataRefreshRetry = false,
            )
        }
    }

    private suspend fun loadAndDecryptPreview(
        repo: EntePublicAlbumRepository,
        accessToken: String,
        fileId: Long,
        record: EnteFileRecord,
        fileKey: ByteArray,
    ): ByteArray {
        val header = record.thumbnailDecryptionHeader
        if (header.isBlank()) {
            throw IllegalStateException("Missing preview decryption header")
        }

        val data = downloadPreviewWithRetry(
            repo = repo,
            accessToken = accessToken,
            fileId = fileId,
        )

        return EnteCrypto.decryptBlobBytes(
            encryptedData = data,
            decryptionHeaderB64 = header,
            key = fileKey,
        )
    }

    private suspend fun downloadFileWithRetry(
        repo: EntePublicAlbumRepository,
        accessToken: String,
        fileId: Long,
    ): ByteArray {
        return downloadWithBackoff(
            label = "full",
            fileId = fileId,
            retryDelaysMs = fullImageRetryDelaysMs,
        ) {
            repo.downloadFile(accessToken, fileId)
        }
    }

    private suspend fun downloadPreviewWithRetry(
        repo: EntePublicAlbumRepository,
        accessToken: String,
        fileId: Long,
    ): ByteArray {
        return downloadWithBackoff(
            label = "preview",
            fileId = fileId,
            retryDelaysMs = previewRetryDelaysMs,
        ) {
            repo.downloadPreview(accessToken, fileId)
        }
    }

    private suspend fun downloadWithBackoff(
        label: String,
        fileId: Long,
        retryDelaysMs: LongArray,
        fetch: suspend () -> ByteArray,
    ): ByteArray {
        val maxAttempts = retryDelaysMs.size + 1
        var lastError: Throwable? = null

        for (attemptIndex in 0 until maxAttempts) {
            val attempt = attemptIndex + 1
            val attemptStartedAt = System.currentTimeMillis()
            AppLog.info("Ente", "Downloading $label bytes for file $fileId (attempt $attempt/$maxAttempts)")

            try {
                val data = fetch()
                if (data.isEmpty()) {
                    throw IllegalStateException("Empty $label data")
                }

                val elapsed = System.currentTimeMillis() - attemptStartedAt
                AppLog.info(
                    "Ente",
                    "Downloaded $label bytes for file $fileId (${data.size} bytes, ${elapsed}ms, attempt $attempt/$maxAttempts)",
                )
                return data
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                lastError = e

                val retriable = isRetriableDownloadError(e)
                val hasMoreAttempts = attemptIndex < retryDelaysMs.lastIndex
                val elapsed = System.currentTimeMillis() - attemptStartedAt

                if (!retriable || !hasMoreAttempts) {
                    AppLog.error(
                        "Ente",
                        "Download failed for $label file $fileId (attempt $attempt/$maxAttempts, ${elapsed}ms, retriable=$retriable)",
                        e,
                    )
                    throw e
                }

                val delayMs = retryDelaysMs[attemptIndex]
                AppLog.error(
                    "Ente",
                    "Download failed for $label file $fileId (attempt $attempt/$maxAttempts, ${elapsed}ms). Retrying in ${delayMs}ms",
                    e,
                )
                delay(delayMs)
            }
        }

        throw (lastError ?: IllegalStateException("$label download failed for file $fileId"))
    }

    private fun isRetriableDownloadError(error: Throwable): Boolean {
        val msg = error.message?.lowercase().orEmpty()
        return msg.contains("stream pull failed") ||
            msg.contains("http 5") ||
            msg.contains("http 429") ||
            msg.contains("http 408") ||
            msg.contains("timeout") ||
            msg.contains("temporar") ||
            msg.contains("connection") ||
            msg.contains("eof") ||
            msg.contains("socket")
    }

    private fun isRetriableDecryptError(error: Throwable): Boolean {
        val msg = error.message?.lowercase().orEmpty()
        return msg.contains("stream pull failed") ||
            msg.contains("decrypt") ||
            msg.contains("authentication") ||
            msg.contains("invalid")
    }

    private fun isCacheFresh(
        record: EnteFileRecord,
        cachedFile: File,
        metaFile: File,
        cache: EnteImageCache,
    ): Boolean {
        val updatedAt = record.updationTime
        if (updatedAt <= 0L) return true
        val cachedUpdatedAt = cache.readUpdateTime(metaFile) ?: cachedFile.lastModified()
        if (cachedUpdatedAt <= 0L) return false
        return cachedUpdatedAt >= updatedAt
    }

    private fun touchCacheFile(file: File) {
        runCatching { file.setLastModified(System.currentTimeMillis()) }
    }

    private fun isLikelyUnsupported(info: ImageInfo?, resolvedMime: String?): Boolean {
        val mime = resolvedMime ?: info?.mime?.lowercase().orEmpty()
        if (mime.isBlank()) return false
        if (mime in ImageFormatClassifier.displaySupportedMimes) return false
        return !mime.startsWith("image/")
    }

    private fun canKeepOriginalBytes(info: ImageInfo?, resolvedMime: String?): Boolean {
        val mime = resolvedMime ?: info?.mime?.lowercase().orEmpty()
        if (mime.isBlank()) return true
        if (mime in ImageFormatClassifier.displaySupportedMimes) return true
        return mime.startsWith("image/")
    }

    private fun resolveMime(maybeMime: String?, bytes: ByteArray): String? {
        return ImageFormatClassifier.resolveMime(maybeMime, bytes)
    }

    private fun detectMimeFromFile(file: File): String? {
        return ImageFormatClassifier.detectMime(file)
    }

    private fun maybeTranscodeImage(
        bytes: ByteArray,
        info: ImageInfo?,
    ): ByteArray? {
        if (info != null) {
            val mime = info.mime.lowercase()
            if (mime == "image/gif" ||
                (mime == "image/png" && ImageFormatClassifier.isAnimatedPng(bytes)) ||
                (mime == "image/webp" && ImageFormatClassifier.isAnimatedWebp(bytes))
            ) {
                return bytes
            }

            val needsResize = max(info.width, info.height) > maxImageDimension
            val needsOrientationFix = requiresOrientationTransform(info.orientation) &&
                mime !in setOf("image/jpeg", "image/jpg")
            val shouldAttemptTranscode = mime !in ImageFormatClassifier.neverTranscodeMimes &&
                (needsResize || needsOrientationFix || mime !in ImageFormatClassifier.displaySupportedMimes)
            if (!shouldAttemptTranscode) return bytes

            if (needsOrientationFix) {
                AppLog.info("Ente", "Applying orientation fix for mime=$mime orientation=${info.orientation}")
            }

            val sampleSize = calculateSampleSize(info.width, info.height, maxImageDimension)
            val decoded = decodeWithBitmapFactory(bytes, sampleSize)
            if (decoded != null) {
                val normalized = applyOrientation(decoded, info.orientation)
                val output = compressBitmap(normalized, sampleSize)
                if (normalized != decoded) {
                    normalized.recycle()
                }
                decoded.recycle()
                return output
            }
        }

        val decoded = decodeWithImageDecoder(bytes, maxImageDimension)
        if (decoded != null) {
            val orientation = info?.orientation ?: ExifInterface.ORIENTATION_NORMAL
            val normalized = applyOrientation(decoded.bitmap, orientation)
            val output = compressBitmap(normalized, decoded.sampleSize)
            if (normalized != decoded.bitmap) {
                normalized.recycle()
            }
            decoded.bitmap.recycle()
            return output
        }

        return null
    }

    private fun decodeWithBitmapFactory(bytes: ByteArray, sampleSize: Int): Bitmap? {
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }

    private fun decodeWithImageDecoder(bytes: ByteArray, maxDimension: Int): DecodedBitmap? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null

        var sampleSize = 1
        val bitmap = runCatching {
            val source = ImageDecoder.createSource(ByteBuffer.wrap(bytes))
            ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                sampleSize = calculateSampleSize(info.size.width, info.size.height, maxDimension)
                decoder.setTargetSampleSize(sampleSize)
            }
        }.getOrNull() ?: return null

        return DecodedBitmap(bitmap, sampleSize)
    }

    private fun compressBitmap(bitmap: Bitmap, sampleSize: Int): ByteArray {
        val output = ByteArrayOutputStream()
        val quality = if (sampleSize > 1) 96 else 98
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, output)
        return output.toByteArray()
    }

    private data class DecodedBitmap(
        val bitmap: Bitmap,
        val sampleSize: Int,
    )

    private fun inspectImage(bytes: ByteArray): ImageInfo? {
        if (bytes.isEmpty()) return null
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        if (options.outWidth <= 0 || options.outHeight <= 0) return null
        val mime = options.outMimeType?.lowercase().orEmpty()
        val orientation = readExifOrientation(bytes)
        return ImageInfo(options.outWidth, options.outHeight, mime, orientation)
    }

    private fun calculateSampleSize(width: Int, height: Int, maxDimension: Int): Int {
        var sample = 1
        val maxSide = max(width, height)
        while (maxSide / sample > maxDimension) {
            sample *= 2
        }
        return sample
    }

    private fun readExifOrientation(bytes: ByteArray): Int {
        return runCatching {
            ByteArrayInputStream(bytes).use { stream ->
                ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                )
            }
        }.getOrDefault(ExifInterface.ORIENTATION_NORMAL)
    }

    private fun requiresOrientationTransform(orientation: Int): Boolean {
        return orientation != ExifInterface.ORIENTATION_NORMAL &&
            orientation != ExifInterface.ORIENTATION_UNDEFINED
    }

    private fun applyOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.setRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.setRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
            else -> return bitmap
        }

        return runCatching {
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        }.getOrDefault(bitmap)
    }

    private data class ImageInfo(
        val width: Int,
        val height: Int,
        val mime: String,
        val orientation: Int,
    )

    class Factory(
        private val appContext: Context,
    ) : Fetcher.Factory<Uri> {
        override fun create(data: Uri, options: Options, imageLoader: ImageLoader): Fetcher? {
            if (data.scheme != "ente") return null
            return EnteUriFetcher(appContext, data)
        }
    }
}
