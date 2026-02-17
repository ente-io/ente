package io.ente.ensu.data.auth

import io.ente.ensu.data.network.AuthTokenProvider
import io.ente.ensu.data.storage.CredentialStore

class EnsuAuthTokenProvider(private val credentialStore: CredentialStore) : AuthTokenProvider {
    override suspend fun getAuthToken(): String? = credentialStore.getToken()
}
