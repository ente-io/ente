package io.ente.ensu.data.network

interface AuthTokenProvider {
    suspend fun getAuthToken(): String?
}
