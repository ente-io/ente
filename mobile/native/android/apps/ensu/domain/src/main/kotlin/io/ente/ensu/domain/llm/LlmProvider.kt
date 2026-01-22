package io.ente.ensu.domain.llm

import java.io.File


data class LlmModelTarget(
    val id: String,
    val url: String,
    val mmprojUrl: String? = null,
    val contextLength: Int? = null,
    val maxTokens: Int? = null
)

data class DownloadProgress(
    val percent: Int,
    val status: String
)

enum class LlmMessageRole {
    User,
    Assistant,
    System
}

data class LlmMessage(
    val text: String,
    val role: LlmMessageRole,
    val hasAttachments: Boolean = false
)

data class GenerationSummary(
    val jobId: Long,
    val generatedTokens: Int,
    val totalTimeMs: Long?
)

interface LlmProvider {
    suspend fun ensureModelReady(
        target: LlmModelTarget,
        onProgress: (DownloadProgress) -> Unit
    )

    suspend fun generateChat(
        target: LlmModelTarget,
        messages: List<LlmMessage>,
        imageFiles: List<File>,
        temperature: Float,
        maxTokens: Int,
        onToken: (String) -> Unit
    ): GenerationSummary

    fun isModelDownloaded(target: LlmModelTarget): Boolean
    suspend fun estimateModelDownloadSize(target: LlmModelTarget): Long?

    fun stopGeneration()
    fun resetContext()
    fun cancelDownload()
}
