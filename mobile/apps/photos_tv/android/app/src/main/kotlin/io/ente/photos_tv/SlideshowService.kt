package io.ente.photos_tv

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.OkHttpClient
import okhttp3.Request
import kotlin.math.max
import kotlin.random.Random

internal class SlideshowService(
    private val client: OkHttpClient,
    private val payload: CastPayload,
    private val imageCache: DiskImageCache,
    private val cryptoBox: CryptoBox,
) {
    private var files = emptyList<CastFile>()
    private var index = 0

    fun nextImage(): ByteArray? {
        if (index >= files.size) refreshFiles()
        if (files.isEmpty()) return null
        val file = files[index]
        index += 1
        return downloadImage(file)
    }

    private fun refreshFiles() {
        val decryptedFiles = mutableListOf<CastFile>()
        for (remoteFile in getRemoteFiles()) {
            val file = decryptFile(remoteFile)
            if (file != null && file.isImage) decryptedFiles.add(file)
        }
        files = decryptedFiles.shuffled(Random.Default)
        index = 0
    }

    private fun getRemoteFiles(): List<JsonObject> {
        val filesById = linkedMapOf<Long, JsonObject>()
        var sinceTime = 0L
        while (true) {
            val request = Request.Builder()
                .url("$API_ORIGIN/cast/diff?sinceTime=$sinceTime")
                .header("X-Cast-Access-Token", payload.castToken)
                .get()
                .build()
            client.newCall(request).execute().use { response ->
                response.ensureOk()
                val body = JsonConfig.value.parseToJsonElement(response.body!!.string()).jsonObject
                for (item in body.getValue("diff").jsonArray.map { it.jsonObject }) {
                    sinceTime = max(sinceTime, item.getLong("updationTime"))
                    if (item["isDeleted"]?.jsonPrimitive?.booleanOrNull == true) filesById.remove(item.getLong("id")) else filesById[item.getLong("id")] = item
                }
                if (body["hasMore"]?.jsonPrimitive?.booleanOrNull != true) return filesById.values.toList()
            }
        }
    }

    private fun decryptFile(item: JsonObject): CastFile? {
        val key = cryptoBox.decrypt(
            input = cryptoBox.base64Decode(item.getString("encryptedKey")),
            key = cryptoBox.base64Decode(payload.collectionKey),
            nonce = cryptoBox.base64Decode(item.getString("keyDecryptionNonce")),
        )
        val metadata = item.getValue("metadata").jsonObject
        val metadataBytes = cryptoBox.decryptData(
            input = cryptoBox.base64Decode(metadata.getString("encryptedData")),
            key = key,
            header = cryptoBox.base64Decode(metadata.getString("decryptionHeader")),
        )
        return castFileFromRemote(item, key, metadataBytes)
    }

    private fun downloadImage(file: CastFile): ByteArray {
        val cachedImage = imageCache.read(file)
        if (cachedImage != null) {
            imageCache.markUsed(file)
            return cachedImage
        }
        val imageBytes = downloadAndDecryptImage(file)
        imageCache.write(file, imageBytes)
        return imageBytes
    }

    private fun downloadAndDecryptImage(file: CastFile): ByteArray {
        val request = Request.Builder()
            .url("$CAST_WORKER_ORIGIN/preview/?fileID=${file.id}")
            .header("X-Cast-Access-Token", payload.castToken)
            .get()
            .build()
        client.newCall(request).execute().use { response ->
            response.ensureOk()
            return cryptoBox.decryptData(
                input = response.body!!.bytes(),
                key = file.key,
                header = cryptoBox.base64Decode(file.preview.getString("decryptionHeader")),
            )
        }
    }
}
