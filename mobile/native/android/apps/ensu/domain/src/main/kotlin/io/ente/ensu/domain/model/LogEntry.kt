package io.ente.ensu.domain.model

data class LogEntry(
    val id: String,
    val timestampMillis: Long,
    val level: LogLevel,
    val tag: String? = null,
    val message: String,
    val details: String? = null
)

enum class LogLevel {
    Info,
    Warning,
    Error
}
