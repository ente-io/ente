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

    override fun log(level: LogLevel, message: String, details: String?) {
        val entry = LogEntry(
            id = UUID.randomUUID().toString(),
            timestampMillis = System.currentTimeMillis(),
            level = level,
            message = message,
            details = details
        )
        _logs.update { listOf(entry) + it }
    }
}
