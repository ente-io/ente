package io.ente.ensu.data

import io.ente.ensu.domain.preferences.SessionPreferences
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * Small helper to synchronously read the selected session id during bootstrap.
 * This avoids adding suspend functions to AppStore's constructor.
 */
fun SessionPreferences.getSelectedSessionIdSync(): String? = runBlocking {
    selectedSessionId.first()
}

fun SessionPreferences.getSessionSummariesSync(): Map<String, String> = runBlocking {
    sessionSummaries.first()
}
