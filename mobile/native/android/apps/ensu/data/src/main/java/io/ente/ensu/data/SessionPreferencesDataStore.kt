package io.ente.ensu.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStoreFile
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import io.ente.ensu.domain.preferences.SessionPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class SessionPreferencesDataStore(context: Context) : SessionPreferences {
    private val json = Json
    private val dataStore: DataStore<Preferences> = PreferenceDataStoreFactory.create {
        context.preferencesDataStoreFile("ensu_session_prefs")
    }

    override val selectedSessionId: Flow<String?> = dataStore.data.map { preferences ->
        preferences[Keys.SELECTED_SESSION_ID]
    }

    override val sessionSummaries: Flow<Map<String, String>> = dataStore.data.map { preferences ->
        decodeSessionSummaries(preferences[Keys.SESSION_SUMMARIES])
    }

    override suspend fun setSelectedSessionId(sessionId: String?) {
        dataStore.edit { preferences ->
            if (sessionId == null) {
                preferences.remove(Keys.SELECTED_SESSION_ID)
            } else {
                preferences[Keys.SELECTED_SESSION_ID] = sessionId
            }
        }
    }

    override suspend fun setSessionSummary(sessionId: String, summary: String?) {
        dataStore.edit { preferences ->
            val summaries =
                decodeSessionSummaries(preferences[Keys.SESSION_SUMMARIES]).toMutableMap()
            if (summary.isNullOrBlank()) {
                summaries.remove(sessionId)
            } else {
                summaries[sessionId] = summary
            }
            preferences[Keys.SESSION_SUMMARIES] = json.encodeToString(summaries)
        }
    }

    private fun decodeSessionSummaries(raw: String?): Map<String, String> {
        if (raw.isNullOrBlank()) return emptyMap()
        return runCatching {
            json.decodeFromString<Map<String, String>>(raw).filterValues {
                it.isNotBlank()
            }
        }.getOrDefault(emptyMap())
    }

    private object Keys {
        val SELECTED_SESSION_ID = stringPreferencesKey("selected_session_id")
        val SESSION_SUMMARIES = stringPreferencesKey("session_summaries")
    }
}
