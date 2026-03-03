package io.ente.ensu.data.network

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

class HttpClient(
    private val client: OkHttpClient = OkHttpClient()
) {
    private val json = Json { ignoreUnknownKeys = true }
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    suspend fun <T> request(
        url: okhttp3.HttpUrl,
        method: HttpMethod,
        parameters: Map<String, Any?>? = null,
        headers: Map<String, String>? = null,
        responseSerializer: KSerializer<T>
    ): T = withContext(Dispatchers.IO) {
        val finalUrl = if (method == HttpMethod.GET && parameters != null) {
            val builder = url.newBuilder()
            parameters.forEach { (key, value) ->
                builder.addQueryParameter(key, value?.toString())
            }
            builder.build()
        } else {
            url
        }

        val body = if (method == HttpMethod.POST || method == HttpMethod.PUT || method == HttpMethod.PATCH) {
            val payload = JSONObject(parameters ?: emptyMap<String, Any>()).toString()
            payload.toRequestBody(jsonMediaType)
        } else {
            null
        }

        val requestBuilder = Request.Builder().url(finalUrl).method(method.value, body)
        headers?.forEach { (key, value) -> requestBuilder.addHeader(key, value) }

        val response = client.newCall(requestBuilder.build()).execute()
        val responseBody = response.body?.string().orEmpty()

        if (!response.isSuccessful) {
            val message = runCatching {
                json.decodeFromString(ErrorResponse.serializer(), responseBody).message
            }.getOrNull()
            throw ApiException(response.code, message)
        }

        if (responseSerializer == EmptyResponse.serializer()) {
            @Suppress("UNCHECKED_CAST")
            return@withContext EmptyResponse as T
        }

        return@withContext try {
            json.decodeFromString(responseSerializer, responseBody)
        } catch (error: Exception) {
            throw InvalidResponseException(error.message ?: "Invalid response")
        }
    }
}
