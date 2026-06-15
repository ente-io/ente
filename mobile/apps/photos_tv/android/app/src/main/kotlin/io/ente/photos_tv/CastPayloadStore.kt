package io.ente.photos_tv

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.serialization.encodeToString

internal class CastPayloadStore(context: Context) {
    private val preferences = EncryptedSharedPreferences.create(
        context,
        "photos_tv_secure_store",
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )
    var payload: CastPayload? = null
        private set

    fun load() {
        val value = preferences.getString(PAYLOAD_KEY, null)
        payload = value?.let { JsonConfig.value.decodeFromString<CastPayload>(it) }
    }

    fun save(value: CastPayload) {
        payload = value
        preferences.edit().putString(PAYLOAD_KEY, JsonConfig.value.encodeToString(value)).apply()
    }

    fun clear() {
        payload = null
        preferences.edit().remove(PAYLOAD_KEY).apply()
    }
}

private const val PAYLOAD_KEY = "photos_tv_cast_payload"
