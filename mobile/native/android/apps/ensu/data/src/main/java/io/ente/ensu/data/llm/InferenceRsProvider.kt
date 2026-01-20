package io.ente.ensu.data.llm

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
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Call
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max

class InferenceRsProvider(
    private val modelDir: File,
    private val ioDispatcher: kotlinx.coroutines.CoroutineDispatcher = Dispatchers.IO
) : LlmProvider {
    private val httpClient = OkHttpClient()
    private val downloadCancelled = AtomicBoolean(false)
    @Volatile private var downloadCall: Call? = null

    @Volatile private var modelHandle: ModelHandle? = null
    @Volatile private var contextHandle: ContextHandle? = null
    @Volatile private var currentModelId: String? = null
    @Volatile private var currentJobId: Long? = null
    private var backendInitialized = false

    init {
        uniffiEnsureInitialized()
    }

    override suspend fun ensureModelReady(
        target: LlmModelTarget,
        onProgress: (DownloadProgress) -> Unit
    ) {
        withContext(ioDispatcher) {
            if (!backendInitialized) {
                initBackend()
                backendInitialized = true
            }

            if (currentModelId == target.id && contextHandle != null && modelHandle != null) {
                return@withContext
            }

            unloadModel()

            val modelFile = modelPathFor(target)
            val mmprojFile = mmprojPathFor(target)
            val mmprojUrl = target.mmprojUrl

            val downloads = mutableListOf<DownloadTarget>()
            if (!modelFile.exists()) {
                downloads.add(DownloadTarget("Model", target.url, modelFile))
            }
            if (mmprojFile != null && !mmprojUrl.isNullOrBlank() && !mmprojFile.exists()) {
                downloads.add(DownloadTarget("Mmproj", mmprojUrl, mmprojFile))
            }

            if (downloads.isNotEmpty()) {
                downloadCancelled.set(false)
                onProgress(DownloadProgress(0, "Starting download..."))
                modelFile.parentFile?.mkdirs()
                mmprojFile?.parentFile?.mkdirs()

                val lengths = downloads.map { fetchContentLength(it.url) }
                val totalBytes = lengths.filterNotNull().sum()
                val hasTotal = lengths.all { it != null } && totalBytes > 0
                var downloadedSoFar = 0L

                downloads.forEachIndexed { index, download ->
                    val fileTotal = lengths[index]
                    downloadFile(download.url, download.destination) { downloaded, total ->
                        val overallDownloaded = downloadedSoFar + downloaded
                        val percent = if (hasTotal) {
                            ((overallDownloaded * 100) / totalBytes).toInt()
                        } else {
                            val step = 100f / downloads.size
                            val filePercent = total?.let { downloaded.toFloat() / it } ?: 0f
                            ((index * step) + (filePercent * step)).toInt()
                        }
                        val status = if (hasTotal) {
                            "Downloading... ${formatBytes(overallDownloaded)} / ${formatBytes(totalBytes)}"
                        } else {
                            "Downloading ${download.label.lowercase()}... ${formatBytes(downloaded)}"
                        }
                        onProgress(DownloadProgress(percent.coerceIn(0, 99), status))
                    }
                    downloadedSoFar += fileTotal ?: download.destination.length()
                }
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
        maxTokens: Int,
        onToken: (String) -> Unit
    ): GenerationSummary = withContext(ioDispatcher) {
        val context = contextHandle ?: throw IllegalStateException("Model context not loaded")
        val mmprojPath = if (imageFiles.isEmpty()) null else mmprojPathFor(target)?.absolutePath

        val request = GenerateChatRequest(
            messages = messages.map { msg ->
                io.ente.labs.inference_rs.ChatMessage(msg.isUserRole(), msg.text)
            },
            templateOverride = null,
            addAssistant = true,
            imagePaths = imageFiles.map { it.absolutePath },
            mmprojPath = mmprojPath,
            mediaMarker = null,
            maxTokens = maxTokens,
            temperature = temperature,
            topP = null,
            topK = null,
            repeatPenalty = null,
            frequencyPenalty = null,
            presencePenalty = null,
            seed = null,
            stopSequences = null,
            grammar = null
        )

        val summary = generateStreamWithCallback(context, request, onToken)
        GenerationSummary(summary.jobId, summary.generatedTokens ?: 0, summary.totalTimeMs)
    }

    override fun stopGeneration() {
        currentJobId?.let { cancel(it) }
    }

    override fun resetContext() {
        val model = modelHandle ?: return
        val contextParams = ContextParams(
            contextSize = null,
            nThreads = null,
            nBatch = null
        )
        contextHandle?.destroy()
        contextHandle = createContext(model, contextParams)
    }

    override fun cancelDownload() {
        downloadCancelled.set(true)
        downloadCall?.cancel()
    }

    private fun LlmMessage.isUserRole(): String {
        return if (isUser) "user" else "assistant"
    }

    private fun unloadModel() {
        contextHandle?.destroy()
        contextHandle = null
        modelHandle?.destroy()
        modelHandle = null
        currentModelId = null
    }

    private fun loadWithFallbacks(target: LlmModelTarget, modelFile: File) {
        val desiredCtx = target.contextLength ?: 4096
        val contexts = listOf(desiredCtx, 4096, 2048, 1024).distinct().filter { it > 0 }
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
                currentModelId = target.id
                return
            } catch (err: Throwable) {
                lastError = err
            }
        }
        unloadModel()
        throw lastError ?: IllegalStateException("Failed to load model")
    }

    private fun downloadFile(
        url: String,
        dest: File,
        onProgress: (Long, Long?) -> Unit
    ) {
        val tmp = File(dest.absolutePath + ".tmp")
        if (tmp.exists()) tmp.delete()

        val request = Request.Builder().url(url).build()
        val call = httpClient.newCall(request)
        downloadCall = call

        val response = call.execute()
        if (!response.isSuccessful) {
            response.close()
            throw IOException("Download failed: HTTP ${response.code}")
        }

        val body = response.body ?: throw IOException("Empty response body")
        val totalBytes = body.contentLength().takeIf { it > 0 }
        var downloaded = 0L

        FileOutputStream(tmp).use { out ->
            body.byteStream().use { input ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    if (downloadCancelled.get()) {
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

        if (!looksLikeGguf(tmp)) {
            tmp.delete()
            throw IOException("Downloaded file is not GGUF")
        }
        if (dest.exists()) dest.delete()
        tmp.renameTo(dest)
    }

    private fun fetchContentLength(url: String): Long? {
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

    private data class DownloadTarget(
        val label: String,
        val url: String,
        val destination: File
    )

    private fun modelPathFor(target: LlmModelTarget): File {
        val baseDir = File(modelDir, "models")
        val filename = target.url.substringAfterLast('/').ifBlank { "model.gguf" }
        return if (target.id.startsWith("custom:")) {
            val customDir = File(baseDir, "custom")
            File(customDir, "${hash(target.url)}_$filename")
        } else {
            File(baseDir, filename)
        }
    }

    private fun mmprojPathFor(target: LlmModelTarget): File? {
        val url = target.mmprojUrl ?: return null
        val baseDir = File(modelDir, "models")
        val filename = url.substringAfterLast('/').ifBlank { "mmproj.gguf" }
        return if (target.id.startsWith("custom:")) {
            val customDir = File(baseDir, "custom")
            File(customDir, "${hash(url)}_$filename")
        } else {
            File(baseDir, filename)
        }
    }

    private fun looksLikeGguf(file: File): Boolean {
        if (!file.exists() || file.length() < 4) return false
        val header = ByteArray(4)
        file.inputStream().use { input ->
            if (input.read(header) != 4) return false
        }
        return header.contentEquals("GGUF".toByteArray())
    }

    private fun hash(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }

    private fun formatBytes(bytes: Long): String {
        val units = arrayOf("B", "KB", "MB", "GB")
        var size = bytes.toDouble()
        var unitIndex = 0
        while (size >= 1024 && unitIndex < units.size - 1) {
            size /= 1024
            unitIndex++
        }
        return String.format(Locale.US, "%.1f %s", size, units[unitIndex])
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
                        onToken(event.text)
                    }
                    is GenerateEvent.Done -> Unit
                    is GenerateEvent.Error -> {
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
