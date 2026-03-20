package io.ente.ensu.data.llm

import io.ente.ensu.domain.llm.DownloadProgress
import io.ente.ensu.domain.llm.LlmModelTarget
import io.ente.ensu.domain.util.formatBytes
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest

internal object ModelDownloadSupport {
    data class DownloadTarget(
        val label: String,
        val url: String,
        val destination: File
    )

    fun expectedTargets(modelDir: File, target: LlmModelTarget): List<DownloadTarget> {
        val targets = mutableListOf(
            DownloadTarget("Model", target.url, modelPathFor(modelDir, target))
        )
        val mmprojUrl = target.mmprojUrl
        val mmprojPath = mmprojPathFor(modelDir, target)
        if (!mmprojUrl.isNullOrBlank() && mmprojPath != null) {
            targets += DownloadTarget("Mmproj", mmprojUrl, mmprojPath)
        }
        return targets
    }

    fun isTargetDownloaded(modelDir: File, target: LlmModelTarget): Boolean {
        return expectedTargets(modelDir, target).all {
            it.destination.exists() && looksLikeGguf(it.destination)
        }
    }

    fun modelPathFor(modelDir: File, target: LlmModelTarget): File {
        return pathForUrl(modelDir, target, target.url, fallback = "model.gguf")
    }

    fun mmprojPathFor(modelDir: File, target: LlmModelTarget): File? {
        val url = target.mmprojUrl ?: return null
        return pathForUrl(modelDir, target, url, fallback = "mmproj.gguf")
    }

    fun existingDownloadBytes(dest: File): Long {
        if (dest.exists()) return dest.length()
        val tmp = File(dest.absolutePath + ".tmp")
        return tmp.length().takeIf { tmp.exists() && it > 0 } ?: 0L
    }

    fun fetchContentLength(httpClient: OkHttpClient, url: String): Long? {
        val request = Request.Builder().url(url).head().build()
        return try {
            httpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return null
                response.body?.contentLength()?.takeIf { it > 0 }
                    ?: response.header("Content-Length")?.toLongOrNull()
            }
        } catch (_: IOException) {
            null
        }
    }

    fun downloadTargets(
        httpClient: OkHttpClient,
        targets: List<DownloadTarget>,
        onProgress: (DownloadProgress) -> Unit,
        isCancelled: () -> Boolean
    ) {
        val downloads = targets.filterNot { it.destination.exists() }
        if (downloads.isEmpty()) return

        targets.forEach { it.destination.parentFile?.mkdirs() }

        val lengths = targets.map { download ->
            download.destination.length().takeIf { it > 0 } ?: fetchContentLength(httpClient, download.url)
        }
        val totalBytes = lengths.filterNotNull().sum()
        val hasTotal = lengths.all { it != null } && totalBytes > 0
        var downloadedSoFar = targets.zip(lengths).sumOf { (download, total) ->
            existingDownloadBytes(download.destination).coerceAtMost(total ?: existingDownloadBytes(download.destination))
        }

        if (hasTotal && downloadedSoFar > 0) {
            val initialPercent = ((downloadedSoFar * 100) / totalBytes).toInt().coerceIn(0, 99)
            onProgress(
                DownloadProgress(
                    percent = initialPercent,
                    status = "Downloading... ${formatBytes(downloadedSoFar)} / ${formatBytes(totalBytes)}"
                )
            )
        } else {
            onProgress(DownloadProgress(percent = 0, status = "Starting download..."))
        }

        downloads.forEach { download ->
            val expectedIndex = targets.indexOfFirst { it.destination == download.destination }
            val fileTotal = lengths.getOrNull(expectedIndex)
            val existingBytesForFile = existingDownloadBytes(download.destination)
            val bytesBeforeFile = downloadedSoFar - existingBytesForFile
            downloadFile(httpClient, download.url, download.destination, isCancelled) { downloaded, total ->
                val overallDownloaded = bytesBeforeFile + downloaded
                val percent = if (hasTotal) {
                    ((overallDownloaded * 100) / totalBytes).toInt()
                } else {
                    val step = 100f / targets.size
                    val filePercent = total?.let { downloaded.toFloat() / it } ?: 0f
                    ((expectedIndex.coerceAtLeast(0) * step) + (filePercent * step)).toInt()
                }
                val status = if (hasTotal) {
                    "Downloading... ${formatBytes(overallDownloaded)} / ${formatBytes(totalBytes)}"
                } else {
                    "Downloading ${download.label.lowercase()}... ${formatBytes(downloaded)}"
                }
                onProgress(DownloadProgress(percent = percent.coerceIn(0, 99), status = status))
            }
            downloadedSoFar = bytesBeforeFile + (fileTotal ?: existingDownloadBytes(download.destination))
        }
    }

    fun looksLikeGguf(file: File): Boolean {
        if (!file.exists() || file.length() < 4) return false
        val header = ByteArray(4)
        file.inputStream().use { input ->
            if (input.read(header) != 4) return false
        }
        return header.contentEquals("GGUF".toByteArray())
    }

    private fun downloadFile(
        httpClient: OkHttpClient,
        url: String,
        dest: File,
        isCancelled: () -> Boolean,
        onProgress: (Long, Long?) -> Unit
    ) {
        val tmp = File(dest.absolutePath + ".tmp")
        var existing = if (tmp.exists()) tmp.length() else 0L
        if (existing > 0 && !looksLikeGguf(tmp)) {
            tmp.delete()
            existing = 0L
        }

        while (true) {
            val requestBuilder = Request.Builder().url(url)
            if (existing > 0) {
                requestBuilder.header("Range", "bytes=$existing-")
            }
            val call = httpClient.newCall(requestBuilder.build())

            val response = call.execute()
            if (!response.isSuccessful) {
                response.close()
                throw IOException("Download failed: HTTP ${response.code}")
            }

            if (existing > 0 && response.code == 200) {
                response.close()
                tmp.delete()
                existing = 0L
                continue
            }

            val body = response.body ?: throw IOException("Empty response body")
            val totalBytes = resolveTotalBytes(response, existing, body.contentLength())
            if (totalBytes != null && totalBytes <= existing) {
                response.close()
                tmp.delete()
                existing = 0L
                continue
            }

            val append = existing > 0 && response.code == 206
            var downloaded = existing

            FileOutputStream(tmp, append).use { out ->
                body.byteStream().use { input ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    while (true) {
                        if (isCancelled()) {
                            call.cancel()
                            response.close()
                            tmp.delete()
                            throw IOException("Download cancelled")
                        }
                        val read = input.read(buffer)
                        if (read == -1) break
                        out.write(buffer, 0, read)
                        downloaded += read
                        onProgress(downloaded, totalBytes)
                    }
                }
            }
            response.close()

            if (totalBytes != null && downloaded < totalBytes) {
                tmp.delete()
                throw IOException("Download incomplete")
            }

            if (!looksLikeGguf(tmp)) {
                tmp.delete()
                throw IOException("Downloaded file is not GGUF")
            }
            if (dest.exists()) dest.delete()
            tmp.renameTo(dest)
            return
        }
    }

    private fun resolveTotalBytes(
        response: okhttp3.Response,
        existing: Long,
        remainingLength: Long
    ): Long? {
        val contentLength = remainingLength.takeIf { it > 0 }
        if (existing > 0 && response.code == 206) {
            val contentRange = response.header("Content-Range")
            val totalFromRange = contentRange?.substringAfter('/')?.toLongOrNull()
            return totalFromRange ?: contentLength?.let { existing + it }
        }
        return contentLength
    }

    private fun pathForUrl(modelDir: File, target: LlmModelTarget, url: String, fallback: String): File {
        val baseDir = File(modelDir, "models")
        val filename = filenameForUrl(url, fallback)
        return if (target.id.startsWith("custom:")) {
            val customDir = File(baseDir, "custom")
            File(customDir, "${hash(url)}_$filename")
        } else {
            File(baseDir, filename)
        }
    }

    private fun filenameForUrl(url: String, fallback: String): String {
        val withoutQuery = url.substringBefore('?').substringBefore('#')
        return withoutQuery.substringAfterLast('/').ifBlank { fallback }
    }

    private fun hash(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }
}
