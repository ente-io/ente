package io.ente.photos.screensaver.prefs

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private object Keys {
    const val SOURCE = "pref_source"
    const val INTERVAL_MS = "pref_interval_ms"
    const val SHUFFLE = "pref_shuffle"
    const val FIT_MODE = "pref_fit_mode"
    const val ENTE_CACHE_LIMIT = "pref_ente_cache_limit"
    const val ENTE_REFRESH_INTERVAL_MS = "pref_ente_refresh_interval_ms"
    const val OVERLAY = "pref_overlay"

    val sourceKey = stringPreferencesKey(SOURCE)
    val intervalKey = stringPreferencesKey(INTERVAL_MS)
    val shuffleKey = booleanPreferencesKey(SHUFFLE)
    val fitModeKey = stringPreferencesKey(FIT_MODE)
    val enteCacheLimitKey = stringPreferencesKey(ENTE_CACHE_LIMIT)
    val enteRefreshIntervalKey = stringPreferencesKey(ENTE_REFRESH_INTERVAL_MS)
    val overlayKey = stringPreferencesKey(OVERLAY)
}

class PreferencesRepository(private val context: Context) {

    private val defaultSourceRaw: String = "ente_public_album"

    val flow: Flow<SaverSettings> = context.ssaverDataStore.data.map { prefs ->
        val sourceRaw = prefs[Keys.sourceKey] ?: defaultSourceRaw
        val sourceType = when (sourceRaw) {
            "mediastore" -> PhotoSourceType.MEDIASTORE
            "ente_public_album" -> PhotoSourceType.ENTE_PUBLIC_ALBUM
            else -> PhotoSourceType.ENTE_PUBLIC_ALBUM
        }

        val intervalMs = (prefs[Keys.intervalKey] ?: "60000").toLongOrNull() ?: 60_000L

        val shuffle = prefs[Keys.shuffleKey] ?: true

        val fitModeRaw = prefs[Keys.fitModeKey] ?: "crop"
        val fitMode = when (fitModeRaw) {
            "fit" -> FitMode.FIT
            else -> FitMode.CROP
        }

        val enteCacheLimit = (prefs[Keys.enteCacheLimitKey] ?: "50").toIntOrNull() ?: 50
        val enteRefreshIntervalMs =
            (prefs[Keys.enteRefreshIntervalKey] ?: "3600000").toLongOrNull() ?: 3_600_000L

        val overlayModeRaw = prefs[Keys.overlayKey] ?: "normal"
        val overlayMode = when (overlayModeRaw) {
            "alternate" -> OverlayMode.ALTERNATE
            "disable" -> OverlayMode.DISABLE
            else -> OverlayMode.NORMAL
        }

        SaverSettings(
            sourceType = sourceType,
            intervalMs = intervalMs,
            shuffle = shuffle,
            fitMode = fitMode,
            enteCacheLimit = enteCacheLimit,
            enteRefreshIntervalMs = enteRefreshIntervalMs,
            overlayMode = overlayMode,
        )
    }

    suspend fun get(): SaverSettings = flow.first()

    suspend fun resetToDefaults() {
        context.ssaverDataStore.edit { prefs ->
            prefs[Keys.sourceKey] = defaultSourceRaw
            prefs[Keys.intervalKey] = "60000"
            prefs[Keys.shuffleKey] = true
            prefs[Keys.fitModeKey] = "crop"
            prefs[Keys.enteCacheLimitKey] = "50"
            prefs[Keys.enteRefreshIntervalKey] = "3600000"
            prefs[Keys.overlayKey] = "normal"
        }
    }
}
