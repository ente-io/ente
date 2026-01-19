package io.ente.ensu.domain.logging

import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.model.LogLevel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

interface LogRepository {
    val logs: StateFlow<List<LogEntry>>
    fun log(level: LogLevel, message: String, details: String? = null)
}

object NoOpLogRepository : LogRepository {
    private val emptyFlow = MutableStateFlow<List<LogEntry>>(emptyList())
    override val logs: StateFlow<List<LogEntry>> = emptyFlow

    override fun log(level: LogLevel, message: String, details: String?) = Unit
}
