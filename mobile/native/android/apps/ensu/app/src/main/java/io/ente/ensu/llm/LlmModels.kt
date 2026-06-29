package io.ente.ensu.llm



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
