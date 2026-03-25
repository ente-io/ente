package io.ente.ensu.data.llm

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.util.Log
import io.ente.ensu.domain.llm.DownloadProgress
import io.ente.ensu.domain.llm.GenerationSummary
import io.ente.ensu.domain.llm.LlmMessage
import io.ente.ensu.domain.llm.LlmModelTarget
import io.ente.ensu.domain.llm.LlmProvider
import io.ente.labs.inference_rs.ContextHandle
import io.ente.labs.inference_rs.ContextParams
import io.ente.labs.inference_rs.GenerateChatRequest
import io.ente.labs.inference_rs.GenerateEvent
import io.ente.labs.inference_rs.GenerateEventCallback
import io.ente.labs.inference_rs.GenerateSummary as NativeSummary
import io.ente.labs.inference_rs.ModelHandle
import io.ente.labs.inference_rs.ModelLoadParams
import io.ente.labs.inference_rs.initBackend
import io.ente.labs.inference_rs.loadModel
import io.ente.labs.inference_rs.createContext
import io.ente.labs.inference_rs.generateChatStream
import io.ente.labs.inference_rs.cancel
import io.ente.labs.inference_rs.uniffiEnsureInitialized
import io.ente.labs.inference_rs.InferenceException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import java.io.File
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.locks.ReentrantLock
import kotlin.math.max

class InferenceRsProvider(
    context: Context,
    private val modelDir: File,
    private val legacyModelDir: File? = null,
    private val ioDispatcher: kotlinx.coroutines.CoroutineDispatcher = Dispatchers.IO
) : LlmProvider {
    private data class LoadedModelKey(
        val id: String,
        val requestedContextLength: Int?
    )

    @Serializable
    private data class DownloadRecord(
        val downloadId: Long,
        val label: String,
        val url: String,
        val destinationPath: String
    )

    private data class DownloadRow(
        val status: Int,
        val reason: Int,
        val bytesDownloaded: Long,
        val totalBytes: Long
    )

    private val httpClient = OkHttpClient()
    private val appContext = context.applicationContext
    private val externalDownloadsRoot =
        appContext.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
    private val downloadManager =
        appContext.getSystemService(DownloadManager::class.java)
    private val downloadPrefs =
        appContext.getSharedPreferences("ensu.system.downloads", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    @Volatile private var modelHandle: ModelHandle? = null
    @Volatile private var contextHandle: ContextHandle? = null
    @Volatile private var currentModelKey: LoadedModelKey? = null
    @Volatile private var currentContextLength: Int? = null
    @Volatile private var currentJobId: Long? = null
    @Volatile private var manualDownloadCancelled = false
    private var backendInitialized = false
    private val migratedLegacyTargets = java.util.Collections.synchronizedSet(mutableSetOf<String>())
    private val legacyMigrationLocks = ConcurrentHashMap<String, ReentrantLock>()

    init {
        uniffiEnsureInitialized()
        modelDir.mkdirs()
    }

    override suspend fun ensureModelReady(
        target: LlmModelTarget,
        onProgress: (DownloadProgress) -> Unit
    ) {
        withContext(ioDispatcher) {
            val modelKey = LoadedModelKey(target.id, target.contextLength)
            if (!backendInitialized) {
                initBackend()
                backendInitialized = true
            }

            if (currentModelKey == modelKey && contextHandle != null && modelHandle != null) {
                return@withContext
            }

            unloadModel()

            migrateLegacyDownloads(target)
            val modelFile = ModelDownloadSupport.modelPathFor(modelDir, target)
            if (!ModelDownloadSupport.isTargetDownloaded(modelDir, target)) {
                awaitBackgroundDownload(target, onProgress)
            }

            onProgress(DownloadProgress(100, "Loading model..."))
            loadWithFallbacks(target, modelFile)
            onProgress(DownloadProgress(100, "Ready"))
        }
    }

    override suspend fun generateChat(
        target: LlmModelTarget,
        messages: List<LlmMessage>,
        imageFiles: List<File>,
        temperature: Float,
        maxTokens: Int?,
        onToken: (String) -> Unit
    ): GenerationSummary = withContext(ioDispatcher) {
        val context = contextHandle ?: throw IllegalStateException("Model context not loaded")
        currentJobId = null
        val mmprojPath = if (imageFiles.isEmpty()) {
            null
        } else {
            ModelDownloadSupport.mmprojPathFor(modelDir, target)?.absolutePath
        }
        val clampedTemperature = temperature.coerceIn(0.35f, 0.7f)

        val request = GenerateChatRequest(
            messages = messages.map { msg ->
                io.ente.labs.inference_rs.ChatMessage(msg.roleString(), msg.text)
            },
            templateOverride = null,
            addAssistant = true,
            imagePaths = imageFiles.map { it.absolutePath },
            mmprojPath = mmprojPath,
            mediaMarker = null,
            maxTokens = maxTokens,
            temperature = clampedTemperature,
            topP = 0.9f,
            topK = 50,
            repeatPenalty = 1.18f,
            frequencyPenalty = 0f,
            presencePenalty = 0f,
            seed = null,
            stopSequences = null,
            grammar = null
        )

        val summary = generateStreamWithCallback(context, request, onToken)
        GenerationSummary(summary.jobId, summary.generatedTokens ?: 0, summary.totalTimeMs)
    }

    override fun isModelDownloaded(target: LlmModelTarget): Boolean {
        migrateLegacyDownloads(target)
        return isDownloadComplete(target)
    }

    override suspend fun estimateModelDownloadSize(target: LlmModelTarget): Long? = withContext(ioDispatcher) {
        val modelFile = ModelDownloadSupport.modelPathFor(modelDir, target)
        val mmprojFile = ModelDownloadSupport.mmprojPathFor(modelDir, target)
        val mmprojUrl = target.mmprojUrl
        val modelSize = if (modelFile.exists()) {
            modelFile.length().takeIf { it > 0 }
        } else {
            ModelDownloadSupport.fetchContentLength(httpClient, target.url)
        }
        val mmprojSize = if (mmprojFile != null && !mmprojUrl.isNullOrBlank()) {
            if (mmprojFile.exists()) {
                mmprojFile.length().takeIf { it > 0 }
            } else {
                ModelDownloadSupport.fetchContentLength(httpClient, mmprojUrl)
            }
        } else {
            null
        }
        val sizes = listOfNotNull(modelSize, mmprojSize)
        if (sizes.isEmpty()) null else sizes.sum()
    }

    override suspend fun currentDownloadProgress(target: LlmModelTarget): DownloadProgress? =
        withContext(ioDispatcher) {
            migrateLegacyDownloads(target)
            val targets = ModelDownloadSupport.expectedTargets(modelDir, target)
            val records = loadDownloadRecords(target)
            if (records.isEmpty()) {
                if (ModelDownloadSupport.isTargetDownloaded(modelDir, target)) {
                    clearDownloadRecords(target)
                }
                return@withContext null
            }
            val recordsByPath = records.associateBy { it.destinationPath }

            val rowsById = queryDownloadRows(recordsByPath.values.map { it.downloadId })
            var hasActiveDownload = false
            var hasKnownTotal = true
            var downloadedBytes = 0L
            var totalBytes = 0L

            for (download in targets) {
                val record = recordsByPath[download.destination.absolutePath]
                if (record == null) {
                    if (download.destination.exists() && ModelDownloadSupport.looksLikeGguf(download.destination)) {
                        val size = download.destination.length().coerceAtLeast(0L)
                        downloadedBytes += size
                        totalBytes += size
                        continue
                    }
                    hasKnownTotal = false
                    continue
                }
                val row = rowsById[record.downloadId]
                if (row == null) {
                    hasKnownTotal = false
                    continue
                }

                when (row.status) {
                    DownloadManager.STATUS_PENDING,
                    DownloadManager.STATUS_PAUSED,
                    DownloadManager.STATUS_RUNNING -> {
                        hasActiveDownload = true
                        downloadedBytes += row.bytesDownloaded.coerceAtLeast(0L)
                        if (row.totalBytes > 0) {
                            totalBytes += row.totalBytes
                        } else {
                            hasKnownTotal = false
                        }
                    }

                    DownloadManager.STATUS_SUCCESSFUL -> {
                        if (download.destination.exists() &&
                            ModelDownloadSupport.looksLikeGguf(download.destination)
                        ) {
                            val size = download.destination.length().coerceAtLeast(0L)
                            downloadedBytes += size
                            totalBytes += size
                        } else {
                            clearDownloadRecords(target)
                            return@withContext DownloadProgress(-1, "${download.label} download is invalid")
                        }
                    }

                    DownloadManager.STATUS_FAILED -> {
                        clearDownloadRecords(target)
                        return@withContext DownloadProgress(-1, userFacingDownloadFailure(row.reason))
                    }
                }
            }

            if (!hasActiveDownload) {
                if (isDownloadComplete(target)) {
                    clearDownloadRecords(target)
                }
                return@withContext null
            }

            val percent = if (hasKnownTotal && totalBytes > 0) {
                ((downloadedBytes * 100) / totalBytes).toInt().coerceIn(0, 99)
            } else {
                0
            }
            val status = if (hasKnownTotal && totalBytes > 0) {
                "Downloading... ${io.ente.ensu.domain.util.formatBytes(downloadedBytes)} / ${io.ente.ensu.domain.util.formatBytes(totalBytes)}"
            } else {
                "Downloading model..."
            }
            DownloadProgress(percent = percent, status = status)
        }

    override fun loadedContextLength(target: LlmModelTarget): Int? {
        val modelKey = LoadedModelKey(target.id, target.contextLength)
        return if (currentModelKey == modelKey && contextHandle != null && modelHandle != null) {
            currentContextLength
        } else {
            null
        }
    }

    override fun stopGeneration() {
        val jobId = currentJobId
        if (jobId != null) {
            cancel(jobId)
        } else {
            cancel(0)
        }
    }

    override fun resetContext() {
        val model = modelHandle ?: return
        val contextParams = ContextParams(
            contextSize = currentContextLength,
            nThreads = null,
            nBatch = null
        )
        contextHandle?.destroy()
        contextHandle = createContext(model, contextParams)
    }

    override fun cancelDownload() {
        manualDownloadCancelled = true
        val ids = loadAllDownloadRecords().map { it.downloadId }.distinct()
        if (ids.isNotEmpty() && downloadManager != null) {
            downloadManager.remove(*ids.toLongArray())
        }
        clearAllDownloadRecords()
    }

    private fun LlmMessage.roleString(): String {
        return when (role) {
            io.ente.ensu.domain.llm.LlmMessageRole.User -> "user"
            io.ente.ensu.domain.llm.LlmMessageRole.Assistant -> "assistant"
            io.ente.ensu.domain.llm.LlmMessageRole.System -> "system"
        }
    }

    private fun unloadModel() {
        contextHandle?.destroy()
        contextHandle = null
        modelHandle?.destroy()
        modelHandle = null
        currentModelKey = null
        currentContextLength = null
    }

    private fun loadWithFallbacks(target: LlmModelTarget, modelFile: File) {
        val desiredCtx = target.contextLength ?: 12000
        val contexts = listOf(desiredCtx, 12000, 8192, 4096, 2048, 1024).distinct().filter { it > 0 }
        val threads = max(1, Runtime.getRuntime().availableProcessors() - 1)
        val batch = 512

        val modelParams = ModelLoadParams(
            modelPath = modelFile.absolutePath,
            nGpuLayers = 0,
            useMmap = true,
            useMlock = false
        )

        val model = loadModel(modelParams)
        modelHandle = model

        var lastError: Throwable? = null
        for (ctx in contexts) {
            try {
                val contextParams = ContextParams(
                    contextSize = ctx,
                    nThreads = threads,
                    nBatch = batch
                )
                contextHandle = createContext(model, contextParams)
                currentModelKey = LoadedModelKey(target.id, target.contextLength)
                currentContextLength = ctx
                return
            } catch (err: Throwable) {
                lastError = err
            }
        }
        unloadModel()
        throw lastError ?: IllegalStateException("Failed to load model")
    }

    private suspend fun awaitBackgroundDownload(
        target: LlmModelTarget,
        onProgress: (DownloadProgress) -> Unit
    ) {
        if (externalDownloadsRoot == null || downloadManager == null) {
            awaitManualDownload(target, onProgress)
            return
        }
        ensureDownloadsEnqueued(target)
        val maxPolls = 7_200
        var emptyPollCount = 0
        var pollCount = 0
        while (true) {
            val progress = currentDownloadProgress(target)
            if (progress == null) {
                if (isDownloadComplete(target)) {
                    clearDownloadRecords(target)
                    return
                }
                emptyPollCount += 1
                if (emptyPollCount >= 3) {
                    ensureDownloadsEnqueued(target)
                }
            } else {
                emptyPollCount = 0
                if (progress.percent < 0) {
                    throw IOException(progress.status)
                }
                onProgress(progress)
            }
            pollCount += 1
            if (pollCount >= maxPolls) {
                throw IOException("Download timed out")
            }
            delay(500)
        }
    }

    private fun awaitManualDownload(
        target: LlmModelTarget,
        onProgress: (DownloadProgress) -> Unit
    ) {
        manualDownloadCancelled = false
        val targets = ModelDownloadSupport.expectedTargets(modelDir, target)
        ModelDownloadSupport.downloadTargets(
            httpClient,
            targets,
            onProgress,
            isCancelled = { manualDownloadCancelled }
        )
    }

    private fun ensureDownloadsEnqueued(target: LlmModelTarget) {
        val manager = downloadManager ?: return
        val expectedTargets = ModelDownloadSupport.expectedTargets(modelDir, target)
        val existingRecords = loadDownloadRecords(target).associateBy { it.destinationPath }
        val rowsById = queryDownloadRows(existingRecords.values.map { it.downloadId })
        val updatedRecords = mutableListOf<DownloadRecord>()

        expectedTargets.forEach { download ->
            if (download.destination.exists() && ModelDownloadSupport.looksLikeGguf(download.destination)) {
                return@forEach
            }

            val existingRecord = existingRecords[download.destination.absolutePath]
            val existingRow = existingRecord?.let { rowsById[it.downloadId] }
            val keepExisting = existingRecord != null && existingRow != null && existingRow.status in setOf(
                DownloadManager.STATUS_PENDING,
                DownloadManager.STATUS_PAUSED,
                DownloadManager.STATUS_RUNNING,
                DownloadManager.STATUS_SUCCESSFUL
            )
            if (keepExisting) {
                updatedRecords += requireNotNull(existingRecord)
                return@forEach
            }

            if (download.destination.exists() && !ModelDownloadSupport.looksLikeGguf(download.destination)) {
                download.destination.delete()
            }

            val request = DownloadManager.Request(Uri.parse(download.url))
                .setTitle("Downloading model")
                .setDescription(download.label)
                .setMimeType("application/octet-stream")
                .setAllowedOverMetered(true)
                .setAllowedOverRoaming(true)
                .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                .setDestinationInExternalFilesDir(
                    appContext,
                    Environment.DIRECTORY_DOWNLOADS,
                    relativeDestinationPath(download.destination)
                )
            val id = manager.enqueue(request)
            updatedRecords += DownloadRecord(
                downloadId = id,
                label = download.label,
                url = download.url,
                destinationPath = download.destination.absolutePath
            )
        }

        saveDownloadRecords(target, updatedRecords)
    }

    private fun queryDownloadRows(ids: Collection<Long>): Map<Long, DownloadRow> {
        if (ids.isEmpty()) return emptyMap()
        val manager = downloadManager ?: return emptyMap()
        val query = DownloadManager.Query().setFilterById(*ids.toLongArray())
        val rows = mutableMapOf<Long, DownloadRow>()
        manager.query(query)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_ID)
            val statusColumn = cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS)
            val reasonColumn = cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)
            val downloadedColumn =
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
            val totalColumn = cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
            while (cursor.moveToNext()) {
                rows[cursor.getLong(idColumn)] = DownloadRow(
                    status = cursor.getInt(statusColumn),
                    reason = cursor.getInt(reasonColumn),
                    bytesDownloaded = cursor.getLong(downloadedColumn),
                    totalBytes = cursor.getLong(totalColumn)
                )
            }
        }
        return rows
    }

    private fun loadDownloadRecords(target: LlmModelTarget): List<DownloadRecord> {
        val raw = downloadPrefs.getString(downloadPrefsKey(target), null) ?: return emptyList()
        return runCatching { json.decodeFromString<List<DownloadRecord>>(raw) }.getOrDefault(emptyList())
    }

    private fun saveDownloadRecords(target: LlmModelTarget, records: List<DownloadRecord>) {
        val editor = downloadPrefs.edit()
        if (records.isEmpty()) {
            editor.remove(downloadPrefsKey(target))
        } else {
            editor.putString(downloadPrefsKey(target), json.encodeToString(records))
        }
        editor.apply()
    }

    private fun clearDownloadRecords(target: LlmModelTarget) {
        downloadPrefs.edit().remove(downloadPrefsKey(target)).apply()
    }

    private fun loadAllDownloadRecords(): List<DownloadRecord> {
        return downloadPrefs.all.keys
            .filter { it.startsWith(DOWNLOAD_PREF_PREFIX) }
            .flatMap { key ->
                val raw = downloadPrefs.getString(key, null).orEmpty()
                runCatching { json.decodeFromString<List<DownloadRecord>>(raw) }.getOrDefault(emptyList())
            }
    }

    private fun clearAllDownloadRecords() {
        val editor = downloadPrefs.edit()
        downloadPrefs.all.keys
            .filter { it.startsWith(DOWNLOAD_PREF_PREFIX) }
            .forEach(editor::remove)
        editor.apply()
    }

    private fun downloadPrefsKey(target: LlmModelTarget): String = "$DOWNLOAD_PREF_PREFIX${target.id}"

    private fun relativeDestinationPath(destination: File): String {
        val root = externalDownloadsRoot?.absoluteFile?.toPath()?.normalize()
            ?: error("External downloads directory unavailable")
        val destinationPath = destination.absoluteFile.toPath().normalize()
        return root.relativize(destinationPath).toString()
    }

    private fun isDownloadComplete(target: LlmModelTarget): Boolean {
        val records = loadDownloadRecords(target)
        if (records.isEmpty()) {
            return ModelDownloadSupport.isTargetDownloaded(modelDir, target)
        }

        val rowsById = queryDownloadRows(records.map { it.downloadId })
        val hasActiveDownload = rowsById.values.any { row ->
            row.status == DownloadManager.STATUS_PENDING ||
                row.status == DownloadManager.STATUS_PAUSED ||
                row.status == DownloadManager.STATUS_RUNNING
        }
        if (hasActiveDownload) {
            return false
        }

        val isDownloaded = ModelDownloadSupport.isTargetDownloaded(modelDir, target)
        if (isDownloaded) {
            clearDownloadRecords(target)
        }
        return isDownloaded
    }

    private fun migrateLegacyDownloads(target: LlmModelTarget) {
        val legacyDir = legacyModelDir ?: return
        if (legacyDir.absolutePath == modelDir.absolutePath) return
        val migrationLock = legacyMigrationLocks.getOrPut(target.id) { ReentrantLock() }
        migrationLock.lock()

        try {
            if (migratedLegacyTargets.contains(target.id)) {
                return
            }
            val oldTargets = ModelDownloadSupport.expectedTargets(legacyDir, target)
            val newTargets = ModelDownloadSupport.expectedTargets(modelDir, target)
            oldTargets.zip(newTargets).forEach { (oldTarget, newTarget) ->
                if (!ModelDownloadSupport.looksLikeGguf(oldTarget.destination)) {
                    return@forEach
                }
                if (newTarget.destination.exists()) {
                    return@forEach
                }

                newTarget.destination.parentFile?.mkdirs()
                val moved = oldTarget.destination.renameTo(newTarget.destination)
                if (!moved) {
                    runCatching {
                        oldTarget.destination.copyTo(newTarget.destination, overwrite = false)
                        oldTarget.destination.delete()
                    }.onFailure { error ->
                        Log.w(
                            "InferenceRsProvider",
                            "Legacy migration failed for ${oldTarget.destination.absolutePath}",
                            error
                        )
                    }
                }
            }
            migratedLegacyTargets.add(target.id)
        } finally {
            migrationLock.unlock()
            if (!migrationLock.hasQueuedThreads()) {
                legacyMigrationLocks.remove(target.id, migrationLock)
            }
        }
    }

    private fun userFacingDownloadFailure(reason: Int): String {
        return when (reason) {
            DownloadManager.ERROR_INSUFFICIENT_SPACE ->
                "Not enough storage space to download the model. Please free up space and try again."
            DownloadManager.ERROR_DEVICE_NOT_FOUND -> "Download storage is unavailable"
            DownloadManager.ERROR_CANNOT_RESUME -> "Download could not resume"
            DownloadManager.ERROR_UNHANDLED_HTTP_CODE,
            DownloadManager.ERROR_HTTP_DATA_ERROR -> "Download failed. Please try again."
            else -> "Download failed. Please try again."
        }
    }

    companion object {
        private const val DOWNLOAD_PREF_PREFIX = "target."
    }

    private fun generateStreamWithCallback(
        context: ContextHandle,
        request: GenerateChatRequest,
        onToken: (String) -> Unit
    ): NativeSummary {
        var error: Throwable? = null

        val callback = object : GenerateEventCallback {
            override fun onEvent(event: GenerateEvent) {
                when (event) {
                    is GenerateEvent.Text -> {
                        currentJobId = event.jobId
                        if (event.text.isNotEmpty()) {
                            onToken(event.text)
                        }
                    }
                    is GenerateEvent.Done -> {
                        currentJobId = null
                    }
                    is GenerateEvent.Error -> {
                        currentJobId = null
                        error = InferenceException.Message(event.message)
                    }
                }
            }
        }

        val summary = generateChatStream(context, request, callback)

        error?.let { throw it }
        return summary
    }
}
