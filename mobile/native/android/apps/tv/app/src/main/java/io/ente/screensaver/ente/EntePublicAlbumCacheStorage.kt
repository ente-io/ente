package io.ente.photos.screensaver.ente

import android.content.Context
import androidx.security.crypto.EncryptedFile
import androidx.security.crypto.MasterKey
import java.io.File
import java.security.MessageDigest
import org.json.JSONArray
import org.json.JSONObject

class EntePublicAlbumCacheStorage(
    private val appContext: Context,
) {

    data class CacheState(
        val lastSyncTime: Long,
        val files: Map<Long, EnteFileRecord>,
    )

    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(appContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    private val legacyCacheFile: File = File(appContext.filesDir, "ente_public_album_cache.json")

    fun load(accessToken: String): CacheState? {
        val cacheFile = cacheFile(accessToken)
        if (cacheFile.exists()) {
            return loadEncrypted(cacheFile)
        }

        val legacyState = loadLegacy(accessToken) ?: return null
        save(accessToken, legacyState)
        runCatching { legacyCacheFile.delete() }
        return legacyState
    }

    fun save(accessToken: String, state: CacheState) {
        runCatching {
            val json = JSONObject()
            json.put("lastSyncTime", state.lastSyncTime)

            val filesArr = JSONArray()
            state.files.values.forEach { file ->
                val obj = JSONObject()
                obj.put("id", file.id)
                obj.put("encryptedKey", file.encryptedKey)
                obj.put("keyDecryptionNonce", file.keyDecryptionNonce)
                obj.put("thumbnailDecryptionHeader", file.thumbnailDecryptionHeader)
                obj.put("fileDecryptionHeader", file.fileDecryptionHeader)
                obj.put("metadataEncryptedData", file.metadataEncryptedData)
                obj.put("metadataDecryptionHeader", file.metadataDecryptionHeader)
                file.pubMagicMetadataData?.let { obj.put("pubMagicMetadataData", it) }
                file.pubMagicMetadataHeader?.let { obj.put("pubMagicMetadataHeader", it) }
                if (file.pubMagicMetadataVersion > 0) {
                    obj.put("pubMagicMetadataVersion", file.pubMagicMetadataVersion)
                }
                obj.put("updationTime", file.updationTime)
                file.fileType?.let { obj.put("fileType", it) }
                filesArr.put(obj)
            }
            json.put("files", filesArr)

            writeEncrypted(cacheFile(accessToken), json.toString().toByteArray(Charsets.UTF_8))
        }
    }

    fun clear(accessToken: String) {
        runCatching { cacheFile(accessToken).delete() }
        runCatching { legacyCacheFile.delete() }
    }

    fun clearAll() {
        runCatching { legacyCacheFile.delete() }
        val files = appContext.filesDir.listFiles() ?: return
        files.forEach { file ->
            if (file.name.startsWith("ente_public_album_cache_") && file.name.endsWith(".json.enc")) {
                runCatching { file.delete() }
            }
        }
    }

    private fun loadEncrypted(cacheFile: File): CacheState? {
        return runCatching {
            val bytes = readEncrypted(cacheFile) ?: return@runCatching null
            parseJson(JSONObject(String(bytes, Charsets.UTF_8)))
        }.getOrNull()
    }

    private fun loadLegacy(accessToken: String): CacheState? {
        if (!legacyCacheFile.exists()) return null
        return runCatching {
            val json = JSONObject(legacyCacheFile.readText())
            val token = json.optString("accessToken")
            if (token != accessToken) return@runCatching null
            parseJson(json)
        }.getOrNull()
    }

    private fun parseJson(json: JSONObject): CacheState {
        val lastSyncTime = json.optLong("lastSyncTime", 0)
        val filesArr = json.optJSONArray("files") ?: JSONArray()
        val files = LinkedHashMap<Long, EnteFileRecord>(filesArr.length())
        for (i in 0 until filesArr.length()) {
            val obj = filesArr.optJSONObject(i) ?: continue
            val id = obj.optLong("id", -1)
            if (id <= 0) continue

            val encryptedKey = obj.optString("encryptedKey").orEmpty()
            val keyDecryptionNonce = obj.optString("keyDecryptionNonce").orEmpty()
            val thumbnailDecryptionHeader = obj.optString("thumbnailDecryptionHeader").orEmpty()
            val fileDecryptionHeader = obj.optString("fileDecryptionHeader").orEmpty()
            val metadataEncryptedData = obj.optString("metadataEncryptedData").orEmpty()
            val metadataDecryptionHeader = obj.optString("metadataDecryptionHeader").orEmpty()
            val pubMagicMetadataData = obj.optString("pubMagicMetadataData").takeIf { it.isNotBlank() }
            val pubMagicMetadataHeader = obj.optString("pubMagicMetadataHeader").takeIf { it.isNotBlank() }
            val pubMagicMetadataVersion = obj.optInt("pubMagicMetadataVersion", 0)
            val fileType = obj.takeIf { it.has("fileType") }?.optInt("fileType")
            val updationTime = obj.optLong("updationTime", 0)

            if (encryptedKey.isBlank() || keyDecryptionNonce.isBlank()) {
                continue
            }

            files[id] = EnteFileRecord(
                id = id,
                encryptedKey = encryptedKey,
                keyDecryptionNonce = keyDecryptionNonce,
                thumbnailDecryptionHeader = thumbnailDecryptionHeader,
                fileDecryptionHeader = fileDecryptionHeader,
                metadataEncryptedData = metadataEncryptedData,
                metadataDecryptionHeader = metadataDecryptionHeader,
                pubMagicMetadataData = pubMagicMetadataData,
                pubMagicMetadataHeader = pubMagicMetadataHeader,
                pubMagicMetadataVersion = pubMagicMetadataVersion,
                updationTime = updationTime,
                fileType = fileType,
            )
        }

        return CacheState(
            lastSyncTime = lastSyncTime,
            files = files,
        )
    }

    private fun cacheFile(accessToken: String): File {
        val tokenHash = sha256Hex(accessToken)
        return File(appContext.filesDir, "ente_public_album_cache_${tokenHash}.json.enc")
    }

    private fun writeEncrypted(file: File, bytes: ByteArray) {
        file.parentFile?.mkdirs()
        val encryptedFile = EncryptedFile.Builder(
            appContext,
            file,
            masterKey,
            EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB,
        ).build()
        encryptedFile.openFileOutput().use { output ->
            output.write(bytes)
        }
    }

    private fun readEncrypted(file: File): ByteArray? {
        if (!file.exists()) return null
        val encryptedFile = EncryptedFile.Builder(
            appContext,
            file,
            masterKey,
            EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB,
        ).build()
        return encryptedFile.openFileInput().use { input ->
            input.readBytes()
        }
    }

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return digest.joinToString("") { b -> "%02x".format(b) }
    }
}
