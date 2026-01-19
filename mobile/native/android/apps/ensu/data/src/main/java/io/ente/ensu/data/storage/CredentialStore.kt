package io.ente.ensu.data.storage

import android.content.Context
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class CredentialStore(context: Context) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "ensu_credentials",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun save(email: String, userId: Long, masterKey: ByteArray, secretKey: ByteArray, token: String) {
        prefs.edit()
            .putString(KEY_EMAIL, email)
            .putLong(KEY_USER_ID, userId)
            .putString(KEY_MASTER_KEY, encode(masterKey))
            .putString(KEY_SECRET_KEY, encode(secretKey))
            .putString(KEY_TOKEN, token)
            .apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    fun getEmail(): String? = prefs.getString(KEY_EMAIL, null)

    fun getToken(): String? = prefs.getString(KEY_TOKEN, null)

    fun getUserId(): Long? {
        val value = prefs.getLong(KEY_USER_ID, -1)
        return if (value == -1L) null else value
    }

    fun isLoggedIn(): Boolean =
        !getToken().isNullOrBlank() && !prefs.getString(KEY_MASTER_KEY, null).isNullOrBlank()

    private fun encode(bytes: ByteArray): String {
        return Base64.encodeToString(bytes, Base64.NO_WRAP or Base64.URL_SAFE)
    }

    companion object {
        private const val KEY_EMAIL = "email"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_MASTER_KEY = "master_key"
        private const val KEY_SECRET_KEY = "secret_key"
        private const val KEY_TOKEN = "token"
    }
}
