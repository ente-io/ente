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

class SessionPreferencesDataStore(context: Context) : SessionPreferences {
    private val dataStore: DataStore<Preferences> = PreferenceDataStoreFactory.create {
        context.preferencesDataStoreFile("ensu_session_prefs")
    }

    override val selectedSessionId: Flow<String?> = dataStore.data.map { preferences ->
        preferences[Keys.SELECTED_SESSION_ID]
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

    private object Keys {
        val SELECTED_SESSION_ID = stringPreferencesKey("selected_session_id")
    }
}
