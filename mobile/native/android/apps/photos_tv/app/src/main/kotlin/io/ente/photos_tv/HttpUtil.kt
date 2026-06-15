package io.ente.photos_tv

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.io.IOException

internal val JSON_MEDIA_TYPE = "application/json".toMediaType()

internal fun Request.Builder.jsonHeaders(): Request.Builder {
    return header("Content-Type", "application/json").header("Accept", "application/json")
}

internal fun String.toJsonRequestBody() = toRequestBody(JSON_MEDIA_TYPE)

internal fun Response.ensureOk() {
    if (isSuccessful) return
    val text = body?.string().orEmpty()
    throw HttpStatusException(code, text)
}

internal class HttpStatusException(
    val statusCode: Int,
    body: String,
) : IOException("HTTP $statusCode: $body")
