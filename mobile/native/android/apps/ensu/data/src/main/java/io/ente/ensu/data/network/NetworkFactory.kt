package io.ente.ensu.data.network

import android.content.Context

internal class NetworkFactory(
    context: Context,
    val configuration: NetworkConfiguration,
    authTokenProvider: AuthTokenProvider? = null
) {
    private val client = ApiClient(
        context = context,
        configuration = configuration,
        authTokenProvider = authTokenProvider
    )

    val authentication: AuthenticationGateway = AuthenticationGateway(client)
}
