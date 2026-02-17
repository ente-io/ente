package io.ente.photos.screensaver.ente

import android.content.Context
import io.ente.photos.screensaver.BuildConfig
import java.io.IOException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Headers
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject

class EntePublicAlbumApi(
    private val appContext: Context,
    private val client: OkHttpClient = OkHttpClient(),
) {

    data class Credentials(
        val accessToken: String,
        val accessTokenJWT: String? = null,
    )

    data class CollectionInfo(
        val albumName: String?,
        val encryptedNameB64: String?,
        val nameDecryptionNonceB64: String?,
        val encryptedPathB64: String?,
        val pathDecryptionNonceB64: String?,
        val passwordEnabled: Boolean,
        val nonce: String?,
        val opsLimit: Long?,
        val memLimit: Long?,
    )

    data class RemoteFile(
        val id: Long,
        val encryptedKey: String,
        val keyDecryptionNonce: String,
        val thumbnailDecryptionHeader: String,
        val fileDecryptionHeader: String,
        val metadataEncryptedData: String,
        val metadataDecryptionHeader: String,
        val pubMagicMetadataData: String?,
        val pubMagicMetadataHeader: String?,
        val pubMagicMetadataVersion: Int,
        val updationTime: Long,
        val isDeleted: Boolean,
    )

    data class DiffResponse(
        val diff: List<RemoteFile>,
        val hasMore: Boolean,
    )

    suspend fun getCollectionInfo(credentials: Credentials): CollectionInfo {
        val url = "https://api.ente.io/public-collection/info".toHttpUrl()

        val json = JSONObject(
            executeString(
                Request.Builder()
                    .url(url)
                    .get()
                    .headers(publicAlbumHeaders(credentials))
                    .build(),
            ),
        )

        val collection = json.getJSONObject("collection")
        val albumName = optNonBlank(collection, "name")
        val encryptedName = optNonBlank(collection, "encryptedName", "encrypted_name")
        val nameNonce = optNonBlank(collection, "nameDecryptionNonce", "name_decryption_nonce")

        val attributes = collection.optJSONObject("attributes")
        val encryptedPath = optNonBlank(attributes, "encryptedPath", "encrypted_path")
        val pathNonce = optNonBlank(attributes, "pathDecryptionNonce", "path_decryption_nonce")

        val publicUrls = collection.optJSONArray("publicURLs")
            ?: collection.optJSONArray("public_urls")
            ?: JSONArray()
        val firstUrl = if (publicUrls.length() > 0) publicUrls.optJSONObject(0) else null

        val passwordEnabled = optBoolean(firstUrl, false, "passwordEnabled", "password_enabled")

        val nonce = optNonBlank(firstUrl, "nonce")
        val opsLimit = optPositiveLong(firstUrl, "opsLimit", "ops_limit")
        val memLimit = optPositiveLong(firstUrl, "memLimit", "mem_limit")

        return CollectionInfo(
            albumName = albumName,
            encryptedNameB64 = encryptedName,
            nameDecryptionNonceB64 = nameNonce,
            encryptedPathB64 = encryptedPath,
            pathDecryptionNonceB64 = pathNonce,
            passwordEnabled = passwordEnabled,
            nonce = nonce,
            opsLimit = opsLimit,
            memLimit = memLimit,
        )
    }

    suspend fun verifyPassword(credentials: Credentials, passHash: String): String {
        val url = "https://api.ente.io/public-collection/verify-password".toHttpUrl()
        val body = JSONObject()
            .put("passHash", passHash)
            .toString()
            .toRequestBody("application/json".toMediaType())

        val json = JSONObject(
            executeString(
                Request.Builder()
                    .url(url)
                    .post(body)
                    .headers(publicAlbumHeaders(credentials))
                    .build(),
            ),
        )

        val token = json.optString("jwtToken").orEmpty()
        if (token.isBlank()) {
            throw IOException("Missing jwtToken in response")
        }
        return token
    }

    suspend fun diff(credentials: Credentials, sinceTime: Long): DiffResponse {
        val url = "https://api.ente.io/public-collection/diff".toHttpUrl()
            .newBuilder()
            .addQueryParameter("sinceTime", sinceTime.toString())
            .build()

        val json = JSONObject(
            executeString(
                Request.Builder()
                    .url(url)
                    .get()
                    .headers(publicAlbumHeaders(credentials))
                    .build(),
            ),
        )

        val hasMore = json.optBoolean("hasMore", false)
        val diffArr = json.optJSONArray("diff") ?: JSONArray()

        val diff = ArrayList<RemoteFile>(diffArr.length())
        for (i in 0 until diffArr.length()) {
            val obj = diffArr.optJSONObject(i) ?: continue
            val id = obj.optLong("id", -1)
            if (id <= 0) continue

            val isDeleted = obj.optBoolean("isDeleted", false)
            if (isDeleted) {
                diff.add(
                    RemoteFile(
                        id = id,
                        encryptedKey = "",
                        keyDecryptionNonce = "",
                        thumbnailDecryptionHeader = "",
                        fileDecryptionHeader = "",
                        metadataEncryptedData = "",
                        metadataDecryptionHeader = "",
                        pubMagicMetadataData = null,
                        pubMagicMetadataHeader = null,
                        pubMagicMetadataVersion = 0,
                        updationTime = obj.optLong("updationTime", 0),
                        isDeleted = true,
                    ),
                )
                continue
            }

            val encryptedKey = obj.optString("encryptedKey").orEmpty()
            val keyDecryptionNonce = obj.optString("keyDecryptionNonce").orEmpty()
            val thumbnailHeader = obj.optJSONObject("thumbnail")?.optString("decryptionHeader").orEmpty()
            val fileHeader = obj.optJSONObject("file")?.optString("decryptionHeader").orEmpty()
            val metadataObj = obj.optJSONObject("metadata")
            val metadataEncryptedData = metadataObj?.optString("encryptedData").orEmpty()
            val metadataDecryptionHeader = metadataObj?.optString("decryptionHeader").orEmpty()
            
            val pubMmdObj = obj.optJSONObject("pubMagicMetadata")
            val pubMmdData = pubMmdObj?.optString("data")?.takeIf { it.isNotBlank() }
            val pubMmdHeader = pubMmdObj?.optString("header")?.takeIf { it.isNotBlank() }
            val pubMmdVersion = pubMmdObj?.optInt("version", 0) ?: 0
            
            val updationTime = obj.optLong("updationTime", 0)

            if (encryptedKey.isBlank() || keyDecryptionNonce.isBlank()) {
                continue
            }

            diff.add(
                RemoteFile(
                    id = id,
                    encryptedKey = encryptedKey,
                    keyDecryptionNonce = keyDecryptionNonce,
                    thumbnailDecryptionHeader = thumbnailHeader,
                    fileDecryptionHeader = fileHeader,
                    metadataEncryptedData = metadataEncryptedData,
                    metadataDecryptionHeader = metadataDecryptionHeader,
                    pubMagicMetadataData = pubMmdData,
                    pubMagicMetadataHeader = pubMmdHeader,
                    pubMagicMetadataVersion = pubMmdVersion,
                    updationTime = updationTime,
                    isDeleted = false,
                ),
            )
        }

        return DiffResponse(diff = diff, hasMore = hasMore)
    }

    suspend fun downloadPreview(credentials: Credentials, fileId: Long): ByteArray {
        val url = "https://public-albums.ente.io/preview/".toHttpUrl()
            .newBuilder()
            .addQueryParameter("fileID", fileId.toString())
            .build()

        return executeBytes(
            Request.Builder()
                .url(url)
                .get()
                .headers(publicAlbumHeaders(credentials))
                .build(),
        )
    }

    suspend fun downloadFile(credentials: Credentials, fileId: Long): ByteArray {
        val url = "https://public-albums.ente.io/download/".toHttpUrl()
            .newBuilder()
            .addQueryParameter("fileID", fileId.toString())
            .build()

        return executeBytes(
            Request.Builder()
                .url(url)
                .get()
                .headers(publicAlbumHeaders(credentials))
                .build(),
        )
    }

    private fun publicAlbumHeaders(credentials: Credentials): Headers {
        val builder = Headers.Builder()
            .add("X-Auth-Access-Token", credentials.accessToken)
            .add("X-Client-Package", appContext.packageName)
            .add("X-Client-Version", BuildConfig.VERSION_NAME)

        credentials.accessTokenJWT?.takeIf { it.isNotBlank() }?.let {
            builder.add("X-Auth-Access-Token-JWT", it)
        }

        return builder.build()
    }

    private fun optNonBlank(obj: JSONObject?, vararg keys: String): String? {
        obj ?: return null
        for (key in keys) {
            if (!obj.has(key)) continue
            val value = obj.optString(key, "").trim()
            if (value.isNotEmpty() && !value.equals("null", ignoreCase = true)) {
                return value
            }
        }
        return null
    }

    private fun optPositiveLong(obj: JSONObject?, vararg keys: String): Long? {
        obj ?: return null
        for (key in keys) {
            if (!obj.has(key)) continue
            val raw = obj.opt(key) ?: continue
            val parsed = when (raw) {
                is Number -> raw.toLong()
                is String -> raw.toLongOrNull()
                else -> null
            } ?: continue
            if (parsed > 0L) return parsed
        }
        return null
    }

    private fun optBoolean(obj: JSONObject?, default: Boolean, vararg keys: String): Boolean {
        obj ?: return default
        for (key in keys) {
            if (!obj.has(key)) continue
            val raw = obj.opt(key)
            val parsed = when (raw) {
                is Boolean -> raw
                is Number -> raw.toInt() != 0
                is String -> raw.equals("true", ignoreCase = true) || raw == "1"
                else -> null
            }
            if (parsed != null) return parsed
        }
        return default
    }

    private suspend fun executeString(request: Request): String = withContext(Dispatchers.IO) {
        client.newCall(request).execute().use { res ->
            if (!res.isSuccessful) {
                val body = res.body?.string().orEmpty()
                throw IOException("HTTP ${res.code} ${res.message}: $body")
            }
            res.body?.string().orEmpty()
        }
    }

    private suspend fun executeBytes(request: Request): ByteArray = withContext(Dispatchers.IO) {
        client.newCall(request).execute().use { res ->
            if (!res.isSuccessful) {
                val body = res.body?.string().orEmpty()
                throw IOException("HTTP ${res.code} ${res.message}: $body")
            }
            res.body?.bytes() ?: ByteArray(0)
        }
    }
}
