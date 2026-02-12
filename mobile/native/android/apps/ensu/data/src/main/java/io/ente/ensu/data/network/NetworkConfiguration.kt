package io.ente.ensu.data.network

import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl


data class NetworkConfiguration(
    val apiEndpoint: HttpUrl,
    val accountsEndpoint: HttpUrl? = null,
    val castEndpoint: HttpUrl? = null,
    val publicAlbumsEndpoint: HttpUrl? = null,
    val familyEndpoint: HttpUrl? = null
) {
    companion object {
        fun selfHosted(baseUrl: HttpUrl): NetworkConfiguration {
            val normalized = baseUrl.newBuilder().build()
            return NetworkConfiguration(
                apiEndpoint = normalized,
                accountsEndpoint = normalized.newBuilder().addPathSegment("accounts").build(),
                castEndpoint = normalized.newBuilder().addPathSegment("cast").build(),
                publicAlbumsEndpoint = normalized.newBuilder().addPathSegment("public-albums").build(),
                familyEndpoint = normalized.newBuilder().addPathSegment("family").build()
            )
        }

        val default: NetworkConfiguration = NetworkConfiguration(
            apiEndpoint = "https://api.ente.io".toHttpUrl(),
            accountsEndpoint = "https://accounts.ente.io".toHttpUrl(),
            castEndpoint = "https://api.ente.io".toHttpUrl(),
            publicAlbumsEndpoint = "https://albums.ente.io".toHttpUrl(),
            familyEndpoint = "https://family.ente.io".toHttpUrl()
        )
    }
}
