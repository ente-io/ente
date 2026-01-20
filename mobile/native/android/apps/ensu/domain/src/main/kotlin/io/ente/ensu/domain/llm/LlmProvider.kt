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

data class LlmMessage(
    val text: String,
    val isUser: Boolean,
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

    fun stopGeneration()
    fun resetContext()
    fun cancelDownload()
}
