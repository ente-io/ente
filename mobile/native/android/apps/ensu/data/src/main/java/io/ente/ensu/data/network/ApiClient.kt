package io.ente.ensu.data.network

import android.content.Context
import kotlinx.serialization.KSerializer

class ApiClient(
    context: Context,
    configuration: NetworkConfiguration,
    private val authTokenProvider: AuthTokenProvider? = null,
    private val httpClient: HttpClient = HttpClient()
) {
    private val endpointResolver = EndpointResolver(configuration)
    private val headersManager = RequestHeadersManager(context)

    suspend fun <T> request(endpoint: ApiEndpoint, serializer: KSerializer<T>): T {
        val url = endpointResolver.resolve(endpoint)
        val headers = headersManager.buildHeaders(authTokenProvider).toMutableMap()
        endpoint.headers?.forEach { (key, value) -> headers.putIfAbsent(key, value) }

        return httpClient.request(
            url = url,
            method = endpoint.method,
            parameters = endpoint.parameters,
            headers = headers,
            responseSerializer = serializer
        )
    }

    suspend fun request(endpoint: ApiEndpoint) {
        request(endpoint, EmptyResponse.serializer())
    }
}
