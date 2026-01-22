package io.ente.ensu.data.logging

import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.model.LogLevel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.util.UUID

class InMemoryLogRepository : LogRepository {
    private val _logs = MutableStateFlow<List<LogEntry>>(emptyList())
    override val logs: StateFlow<List<LogEntry>> = _logs.asStateFlow()

    override fun log(level: LogLevel, message: String, details: String?, tag: String?, throwable: Throwable?) {
        val combinedDetails = buildString {
            if (!details.isNullOrBlank()) {
                append(details)
            }
            if (throwable != null) {
                if (isNotEmpty()) append("\n")
                append(throwable.stackTraceToString())
            }
        }.ifBlank { null }

        val safeMessage = LogSanitizer.sanitize(message).orEmpty()
        val safeDetails = LogSanitizer.sanitize(combinedDetails)

        val entry = LogEntry(
            id = UUID.randomUUID().toString(),
            timestampMillis = System.currentTimeMillis(),
            level = level,
            tag = tag,
            message = safeMessage,
            details = safeDetails
        )
        _logs.update { (listOf(entry) + it).take(500) }
    }
}
