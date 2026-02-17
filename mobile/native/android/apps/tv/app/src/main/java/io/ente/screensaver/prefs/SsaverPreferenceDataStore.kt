package io.ente.photos.screensaver.prefs

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.preference.PreferenceDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

class SsaverPreferenceDataStore(
    private val appContext: Context,
) : PreferenceDataStore() {

    private val job = SupervisorJob()
    private val scope = CoroutineScope(job + Dispatchers.IO)

    override fun putString(key: String, value: String?) {
        val prefKey = stringPreferencesKey(key)
        scope.launch {
            appContext.ssaverDataStore.edit { prefs ->
                if (value == null) {
                    prefs.remove(prefKey)
                } else {
                    prefs[prefKey] = value
                }
            }
        }
    }

    override fun getString(key: String, defValue: String?): String? {
        val prefKey = stringPreferencesKey(key)
        return runBlocking {
            appContext.ssaverDataStore.data.first()[prefKey] ?: defValue
        }
    }

    override fun putBoolean(key: String, value: Boolean) {
        val prefKey = booleanPreferencesKey(key)
        scope.launch {
            appContext.ssaverDataStore.edit { prefs ->
                prefs[prefKey] = value
            }
        }
    }

    override fun getBoolean(key: String, defValue: Boolean): Boolean {
        val prefKey = booleanPreferencesKey(key)
        return runBlocking {
            appContext.ssaverDataStore.data.first()[prefKey] ?: defValue
        }
    }

    fun close() {
        job.cancel()
    }
}
