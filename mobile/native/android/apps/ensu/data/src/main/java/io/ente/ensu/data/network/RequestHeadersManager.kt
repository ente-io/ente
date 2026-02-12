package io.ente.ensu.data.network

import android.content.Context
import java.util.UUID

class RequestHeadersManager(private val context: Context) {
    suspend fun buildHeaders(authTokenProvider: AuthTokenProvider? = null): Map<String, String> {
        val headers = mutableMapOf<String, String>()
        headers["User-Agent"] = "EnteNative-Android"
        headers["X-Client-Package"] = context.packageName
        headers["x-request-id"] = UUID.randomUUID().toString()

        val versionName = runCatching {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName
        }.getOrNull()
        if (!versionName.isNullOrBlank()) {
            headers["X-Client-Version"] = versionName
        }

        val token = authTokenProvider?.getAuthToken()
        if (!token.isNullOrBlank()) {
            headers["X-Auth-Token"] = token
        }

        return headers
    }
}
