package io.ente.ensu.data.network

import okhttp3.HttpUrl

class EndpointResolver(private val configuration: NetworkConfiguration) {
    fun resolve(endpoint: ApiEndpoint): HttpUrl {
        val base = when (endpoint.domain) {
            ApiDomain.Api -> configuration.apiEndpoint
            ApiDomain.Accounts -> configuration.accountsEndpoint ?: configuration.apiEndpoint
            ApiDomain.Cast -> configuration.castEndpoint ?: configuration.apiEndpoint
            ApiDomain.PublicAlbums -> configuration.publicAlbumsEndpoint ?: configuration.apiEndpoint
            ApiDomain.Family -> configuration.familyEndpoint ?: configuration.apiEndpoint
        }

        val trimmedPath = endpoint.path.trimStart('/')
        return base.newBuilder()
            .addEncodedPathSegments(trimmedPath)
            .build()
    }
}
