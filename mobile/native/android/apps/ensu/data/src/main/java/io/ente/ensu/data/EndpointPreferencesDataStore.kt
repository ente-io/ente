package io.ente.ensu.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.endpointPreferences by preferencesDataStore("ensu_developer_settings")

class EndpointPreferencesDataStore(private val context: Context) {
    private val endpointKey = stringPreferencesKey("custom_endpoint")

    val endpointFlow: Flow<String?> = context.endpointPreferences.data.map { prefs ->
        prefs[endpointKey]
    }

    suspend fun setEndpoint(endpoint: String?) {
        context.endpointPreferences.edit { prefs ->
            if (endpoint.isNullOrBlank()) {
                prefs.remove(endpointKey)
            } else {
                prefs[endpointKey] = endpoint
            }
        }
    }
}
