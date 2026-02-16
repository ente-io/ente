package io.ente.photos.screensaver.ente

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class EnteSecureStore(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "ente_secure_store",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    fun saveAlbumPassword(accessToken: String, password: String?) {
        val key = passwordKey(accessToken)
        val trimmed = password?.trim().orEmpty()
        if (trimmed.isBlank()) {
            prefs.edit().remove(key).apply()
        } else {
            prefs.edit().putString(key, trimmed).apply()
        }
    }

    fun getAlbumPassword(accessToken: String): String? {
        return prefs.getString(passwordKey(accessToken), null)
    }

    fun clearAlbumPassword(accessToken: String) {
        prefs.edit().remove(passwordKey(accessToken)).apply()
    }

    private fun passwordKey(accessToken: String): String = "album_password_$accessToken"
}
