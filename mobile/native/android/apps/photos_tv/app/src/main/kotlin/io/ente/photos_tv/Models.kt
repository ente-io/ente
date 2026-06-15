package io.ente.photos_tv

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

internal data class Registration(
    val pairingCode: String,
    val publicKey: String,
    val privateKey: String,
)

@Serializable
internal data class CastPayload(
    val castToken: String,
    @SerialName("collectionID")
    val collectionId: Long,
    val collectionKey: String,
)

internal data class CastFile(
    val id: Long,
    val fileType: Int,
    val key: ByteArray,
    val preview: JsonObject,
) {
    val isImage: Boolean
        get() = fileType == 0 || fileType == 2
}

internal fun castFileFromRemote(
    item: JsonObject,
    key: ByteArray,
    metadataBytes: ByteArray,
): CastFile? {
    val metadata = JsonConfig.value.parseToJsonElement(metadataBytes.decodeToString()).jsonObject
    val preview = item["thumbnail"]?.jsonObject ?: return null
    return CastFile(
        id = item.getLong("id"),
        fileType = metadata.getInt("fileType"),
        key = key,
        preview = preview,
    )
}

internal fun JsonObject.getLong(name: String): Long {
    return getValue(name).jsonPrimitive.content.toLong()
}

internal fun JsonObject.getInt(name: String): Int {
    return getValue(name).jsonPrimitive.int
}

internal fun JsonObject.getString(name: String): String {
    return getValue(name).jsonPrimitive.content
}
