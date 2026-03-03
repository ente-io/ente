package io.ente.ensu.data.logging

import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.model.LogLevel
import java.util.UUID

internal object LogEntryBuilder {
    fun buildEntry(
        level: LogLevel,
        message: String,
        details: String?,
        tag: String?,
        throwable: Throwable?,
        idProvider: () -> String = { UUID.randomUUID().toString() },
        nowProvider: () -> Long = { System.currentTimeMillis() }
    ): LogEntry {
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

        return LogEntry(
            id = idProvider(),
            timestampMillis = nowProvider(),
            level = level,
            tag = tag,
            message = safeMessage,
            details = safeDetails
        )
    }
}
