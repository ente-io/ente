package io.ente.ensu.domain.preferences

import kotlinx.coroutines.flow.Flow

interface SessionPreferences {
    val selectedSessionId: Flow<String?>
    val sessionSummaries: Flow<Map<String, String>>
    suspend fun setSelectedSessionId(sessionId: String?)
    suspend fun setSessionSummary(sessionId: String, summary: String?)
}
