package io.ente.ensu.domain.logging

import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.model.LogLevel
import kotlinx.coroutines.flow.StateFlow

interface LogRepository {
    val logs: StateFlow<List<LogEntry>>
    fun log(
        level: LogLevel,
        message: String,
        details: String? = null,
        tag: String? = null,
        throwable: Throwable? = null
    )
}
