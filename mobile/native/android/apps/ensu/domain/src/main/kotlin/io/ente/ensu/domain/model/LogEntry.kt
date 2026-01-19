package io.ente.ensu.domain.model

data class LogEntry(
    val id: String,
    val timestampMillis: Long,
    val level: LogLevel,
    val message: String,
    val details: String? = null
)

enum class LogLevel {
    Info,
    Warning,
    Error
}
