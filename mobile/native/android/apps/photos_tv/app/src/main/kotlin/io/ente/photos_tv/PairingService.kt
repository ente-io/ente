package io.ente.photos_tv

import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.OkHttpClient
import okhttp3.Request

internal class PairingService(
    private val client: OkHttpClient,
    private val cryptoBox: CryptoBox,
) {
    fun register(): Registration {
        val keyPair = cryptoBox.generateKeyPair()
        val publicKey = cryptoBox.base64(keyPair.publicKey)
        val pairingCode = registerDevice(publicKey)
        return Registration(
            pairingCode = pairingCode,
            publicKey = publicKey,
            privateKey = cryptoBox.base64(keyPair.privateKey),
        )
    }

    fun getCastPayload(registration: Registration): CastPayload? {
        val encryptedCastData = getEncryptedCastData(registration.pairingCode) ?: return null
        val payloadBytes = cryptoBox.openSeal(
            input = cryptoBox.base64Decode(encryptedCastData),
            publicKey = cryptoBox.base64Decode(registration.publicKey),
            privateKey = cryptoBox.base64Decode(registration.privateKey),
        )
        return JsonConfig.value.decodeFromString<CastPayload>(payloadBytes.decodeToString())
    }

    private fun registerDevice(publicKey: String): String {
        val body = buildJsonObject {
            put("publicKey", publicKey)
        }.toString().toJsonRequestBody()
        val request = Request.Builder()
            .url("$API_ORIGIN/cast/device-info")
            .jsonHeaders()
            .post(body)
            .build()
        client.newCall(request).execute().use { response ->
            response.ensureOk()
            return JsonConfig.value.parseToJsonElement(response.body!!.string()).jsonObject.getString("deviceCode")
        }
    }

    private fun getEncryptedCastData(code: String): String? {
        val request = Request.Builder()
            .url("$API_ORIGIN/cast/cast-data/$code")
            .jsonHeaders()
            .get()
            .build()
        client.newCall(request).execute().use { response ->
            response.ensureOk()
            return JsonConfig.value.parseToJsonElement(response.body!!.string()).jsonObject["encCastData"]?.jsonPrimitive?.contentOrNull
        }
    }
}
