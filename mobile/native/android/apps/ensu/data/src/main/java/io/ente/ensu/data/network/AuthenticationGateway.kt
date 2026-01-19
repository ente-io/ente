package io.ente.ensu.data.network

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

internal class AuthenticationGateway(private val client: ApiClient) {
    suspend fun getSrpAttributes(email: String): SrpAttributesResponse {
        return client.request(AuthEndpoint.GetSrpAttributes(email), SrpAttributesResponse.serializer())
    }

    suspend fun createSrpSession(srpUserId: String, clientPub: String): CreateSrpSessionResponse {
        return client.request(
            AuthEndpoint.CreateSrpSession(srpUserId, clientPub),
            CreateSrpSessionResponse.serializer()
        )
    }

    suspend fun verifySrpSession(srpUserId: String, sessionId: String, clientM1: String): AuthorizationResponse {
        return client.request(
            AuthEndpoint.VerifySrpSession(srpUserId, sessionId, clientM1),
            AuthorizationResponse.serializer()
        )
    }

    suspend fun sendLoginOtp(email: String, purpose: String = "login") {
        client.request(AuthEndpoint.SendLoginOtp(email, purpose))
    }

    suspend fun verifyEmail(email: String, otp: String): AuthorizationResponse {
        return client.request(AuthEndpoint.VerifyEmail(email, otp), AuthorizationResponse.serializer())
    }

    suspend fun verifyTotp(sessionId: String, otp: String): AuthorizationResponse {
        return client.request(AuthEndpoint.VerifyTotp(sessionId, otp), AuthorizationResponse.serializer())
    }

    suspend fun getTokenForPasskeySession(sessionId: String): AuthorizationResponse {
        return client.request(
            AuthEndpoint.GetTokenForPasskeySession(sessionId),
            AuthorizationResponse.serializer()
        )
    }
}

@Serializable
internal data class SrpAttributesResponse(
    @SerialName("attributes") val attributes: SrpAttributesDto
)

@Serializable
internal data class SrpAttributesDto(
    @SerialName("srpUserID") val srpUserId: String,
    @SerialName("srpSalt") val srpSalt: String,
    @SerialName("kekSalt") val kekSalt: String,
    @SerialName("memLimit") val memLimit: Int,
    @SerialName("opsLimit") val opsLimit: Int,
    @SerialName("isEmailMFAEnabled") val isEmailMfaEnabled: Boolean
)

@Serializable
internal data class CreateSrpSessionResponse(
    @SerialName("sessionID") val sessionId: String,
    @SerialName("srpB") val srpB: String
)

@Serializable
internal data class KeyAttributesDto(
    @SerialName("kekSalt") val kekSalt: String,
    @SerialName("encryptedKey") val encryptedKey: String,
    @SerialName("keyDecryptionNonce") val keyDecryptionNonce: String,
    @SerialName("publicKey") val publicKey: String,
    @SerialName("encryptedSecretKey") val encryptedSecretKey: String,
    @SerialName("secretKeyDecryptionNonce") val secretKeyDecryptionNonce: String,
    @SerialName("memLimit") val memLimit: Int? = null,
    @SerialName("opsLimit") val opsLimit: Int? = null
)

@Serializable
internal data class AuthorizationResponse(
    @SerialName("keyAttributes") val keyAttributes: KeyAttributesDto? = null,
    @SerialName("encryptedToken") val encryptedToken: String? = null,
    @SerialName("token") val token: String? = null,
    @SerialName("twoFactorSessionID") val twoFactorSessionId: String? = null,
    @SerialName("twoFactorSessionIDV2") val twoFactorSessionIdV2: String? = null,
    @SerialName("passkeySessionID") val passkeySessionId: String? = null,
    @SerialName("accountsUrl") val accountsUrl: String? = null,
    @SerialName("id") val id: Long
) {
    val effectiveTwoFactorSessionId: String?
        get() = twoFactorSessionIdV2 ?: twoFactorSessionId
}
