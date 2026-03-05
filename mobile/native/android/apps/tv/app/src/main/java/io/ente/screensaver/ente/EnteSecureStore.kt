@file:Suppress("PackageDirectoryMismatch")

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

    data class AlbumSecrets(
        val publicUrl: String,
        val accessToken: String,
        val collectionKeyB64: String,
        val accessTokenJWT: String?,
    )

    private object Keys {
        const val PUBLIC_URL = "album_public_url"
        const val ACCESS_TOKEN = "album_access_token"
        const val COLLECTION_KEY_B64 = "album_collection_key_b64"
        const val ACCESS_TOKEN_JWT = "album_access_token_jwt"
    }

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

    fun saveAlbumSecrets(secrets: AlbumSecrets) {
        prefs.edit().apply {
            putString(Keys.PUBLIC_URL, secrets.publicUrl)
            putString(Keys.ACCESS_TOKEN, secrets.accessToken)
            putString(Keys.COLLECTION_KEY_B64, secrets.collectionKeyB64)
            val jwt = secrets.accessTokenJWT?.trim().orEmpty()
            if (jwt.isBlank()) {
                remove(Keys.ACCESS_TOKEN_JWT)
            } else {
                putString(Keys.ACCESS_TOKEN_JWT, jwt)
            }
            apply()
        }
    }

    fun getAlbumSecrets(): AlbumSecrets? {
        val publicUrl = prefs.getString(Keys.PUBLIC_URL, null)?.trim().orEmpty()
        val accessToken = prefs.getString(Keys.ACCESS_TOKEN, null)?.trim().orEmpty()
        val collectionKeyB64 = prefs.getString(Keys.COLLECTION_KEY_B64, null)?.trim().orEmpty()
        val accessTokenJWT = prefs.getString(Keys.ACCESS_TOKEN_JWT, null)?.trim()?.takeIf { it.isNotBlank() }
        if (publicUrl.isBlank() || accessToken.isBlank() || collectionKeyB64.isBlank()) {
            return null
        }
        return AlbumSecrets(
            publicUrl = publicUrl,
            accessToken = accessToken,
            collectionKeyB64 = collectionKeyB64,
            accessTokenJWT = accessTokenJWT,
        )
    }

    fun clearAlbumSecrets() {
        prefs.edit().apply {
            remove(Keys.PUBLIC_URL)
            remove(Keys.ACCESS_TOKEN)
            remove(Keys.COLLECTION_KEY_B64)
            remove(Keys.ACCESS_TOKEN_JWT)
            apply()
        }
    }

    private fun passwordKey(accessToken: String): String = "album_password_$accessToken"
}
