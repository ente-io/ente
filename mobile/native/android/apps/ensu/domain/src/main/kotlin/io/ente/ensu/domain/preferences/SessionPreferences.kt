package io.ente.ensu.domain.preferences

import kotlinx.coroutines.flow.Flow

interface SessionPreferences {
    val selectedSessionId: Flow<String?>
    suspend fun setSelectedSessionId(sessionId: String?)
}
