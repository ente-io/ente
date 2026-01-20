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

    fun getMasterKey(): ByteArray? = prefs.getString(KEY_MASTER_KEY, null)?.let(::decode)

    fun getSecretKey(): ByteArray? = prefs.getString(KEY_SECRET_KEY, null)?.let(::decode)

    /**
     * Returns a stable 32-byte key for encrypting the local chat DB.
     *
     * Rules:
     * - If already stored, reuse it.
     * - Else, if the account master key exists and is 32 bytes, pin it as the chat DB key.
     * - Else, generate a random 32-byte key and persist it.
     */
    fun getOrCreateChatDbKey(): ByteArray {
        prefs.getString(KEY_CHAT_DB_KEY, null)?.let { existing ->
            val decoded = runCatching { decode(existing) }.getOrNull()
            if (decoded != null && decoded.size == 32) return decoded
        }

        val fromMaster = getMasterKey()
        if (fromMaster != null && fromMaster.size == 32) {
            prefs.edit().putString(KEY_CHAT_DB_KEY, encode(fromMaster)).apply()
            return fromMaster
        }

        val generated = ByteArray(32)
        java.security.SecureRandom().nextBytes(generated)
        prefs.edit().putString(KEY_CHAT_DB_KEY, encode(generated)).apply()
        return generated
    }

    fun getUserId(): Long? {
        val value = prefs.getLong(KEY_USER_ID, -1)
        return if (value == -1L) null else value
    }

    fun isLoggedIn(): Boolean =
        !getToken().isNullOrBlank() && !prefs.getString(KEY_MASTER_KEY, null).isNullOrBlank()

    private fun encode(bytes: ByteArray): String {
        return Base64.encodeToString(bytes, Base64.NO_WRAP or Base64.URL_SAFE)
    }

    private fun decode(encoded: String): ByteArray {
        return Base64.decode(encoded, Base64.NO_WRAP or Base64.URL_SAFE)
    }

    companion object {
        private const val KEY_EMAIL = "email"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_MASTER_KEY = "master_key"
        private const val KEY_SECRET_KEY = "secret_key"
        private const val KEY_TOKEN = "token"
        private const val KEY_CHAT_DB_KEY = "chat_db_key"
    }
}
