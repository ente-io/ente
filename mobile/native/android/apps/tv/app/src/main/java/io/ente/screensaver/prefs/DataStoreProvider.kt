package io.ente.photos.screensaver.prefs

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore

internal const val SSAVER_DATASTORE_NAME = "ssaver_prefs"

internal val Context.ssaverDataStore: DataStore<Preferences> by preferencesDataStore(
    name = SSAVER_DATASTORE_NAME,
)
