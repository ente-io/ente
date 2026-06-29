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

    fun getOrCreateChatDbKey(): ByteArray {
        prefs.getString(KEY_CHAT_DB_KEY, null)?.let { existing ->
            val decoded = runCatching { decode(existing) }.getOrNull()
            if (decoded != null && decoded.size == 32) return decoded
        }

        val fromMaster = prefs.getString(KEY_MASTER_KEY, null)
            ?.let { runCatching { decode(it) }.getOrNull() }
        if (fromMaster != null && fromMaster.size == 32) {
            prefs.edit().putString(KEY_CHAT_DB_KEY, encode(fromMaster)).apply()
            return fromMaster
        }

        val generated = ByteArray(32)
        java.security.SecureRandom().nextBytes(generated)
        prefs.edit().putString(KEY_CHAT_DB_KEY, encode(generated)).apply()
        return generated
    }

    private fun encode(bytes: ByteArray): String {
        return Base64.encodeToString(bytes, Base64.NO_WRAP or Base64.URL_SAFE)
    }

    private fun decode(encoded: String): ByteArray {
        return Base64.decode(encoded, Base64.NO_WRAP or Base64.URL_SAFE)
    }

    companion object {
        private const val KEY_MASTER_KEY = "master_key"
        private const val KEY_CHAT_DB_KEY = "chat_db_key"
    }
}
