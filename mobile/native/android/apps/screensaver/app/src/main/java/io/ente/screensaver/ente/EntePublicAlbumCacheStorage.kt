package io.ente.photos.screensaver.ente

import android.content.Context
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class EntePublicAlbumCacheStorage(
    private val appContext: Context,
) {

    data class CacheState(
        val accessToken: String,
        val lastSyncTime: Long,
        val files: Map<Long, EnteFileRecord>,
    )

    private val cacheFile: File = File(appContext.filesDir, "ente_public_album_cache.json")

    fun load(accessToken: String): CacheState? {
        if (!cacheFile.exists()) return null
        return runCatching {
            val json = JSONObject(cacheFile.readText())
            val token = json.optString("accessToken")
            if (token != accessToken) return@runCatching null

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
                val pubMagicMetadataData = obj.optString("pubMagicMetadataData")?.takeIf { it.isNotBlank() }
                val pubMagicMetadataHeader = obj.optString("pubMagicMetadataHeader")?.takeIf { it.isNotBlank() }
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

            CacheState(
                accessToken = token,
                lastSyncTime = lastSyncTime,
                files = files,
            )
        }.getOrNull()
    }

    fun save(state: CacheState) {
        runCatching {
            val json = JSONObject()
            json.put("accessToken", state.accessToken)
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

            val tmp = File(cacheFile.parentFile, cacheFile.name + ".tmp")
            tmp.writeText(json.toString())
            if (!tmp.renameTo(cacheFile)) {
                tmp.copyTo(cacheFile, overwrite = true)
                tmp.delete()
            }
        }
    }

    fun clear() {
        runCatching { cacheFile.delete() }
    }
}
