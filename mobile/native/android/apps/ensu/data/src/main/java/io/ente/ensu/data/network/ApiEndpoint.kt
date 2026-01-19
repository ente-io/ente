package io.ente.ensu.data.network

interface ApiEndpoint {
    val domain: ApiDomain
    val path: String
    val method: HttpMethod
    val parameters: Map<String, Any?>?
    val headers: Map<String, String>?
}

sealed class AuthEndpoint : ApiEndpoint {
    data class GetSrpAttributes(val email: String) : AuthEndpoint()
    data class CreateSrpSession(val srpUserId: String, val clientPub: String) : AuthEndpoint()
    data class VerifySrpSession(val srpUserId: String, val sessionId: String, val clientM1: String) : AuthEndpoint()
    data class SendLoginOtp(val email: String, val purpose: String) : AuthEndpoint()
    data class VerifyEmail(val email: String, val otp: String) : AuthEndpoint()
    data class VerifyTotp(val sessionId: String, val otp: String) : AuthEndpoint()
    data class GetTokenForPasskeySession(val sessionId: String) : AuthEndpoint()

    override val domain: ApiDomain = ApiDomain.Api

    override val path: String
        get() = when (this) {
            is GetSrpAttributes -> "/users/srp/attributes"
            is CreateSrpSession -> "/users/srp/create-session"
            is VerifySrpSession -> "/users/srp/verify-session"
            is SendLoginOtp -> "/users/ott"
            is VerifyEmail -> "/users/verify-email"
            is VerifyTotp -> "/users/two-factor/verify"
            is GetTokenForPasskeySession -> "/users/two-factor/passkeys/get-token"
        }

    override val method: HttpMethod
        get() = when (this) {
            is GetSrpAttributes, is GetTokenForPasskeySession -> HttpMethod.GET
            is CreateSrpSession, is VerifySrpSession, is SendLoginOtp, is VerifyEmail, is VerifyTotp -> HttpMethod.POST
        }

    override val parameters: Map<String, Any?>?
        get() = when (this) {
            is GetSrpAttributes -> mapOf("email" to email)
            is CreateSrpSession -> mapOf("srpUserID" to srpUserId, "srpA" to clientPub)
            is VerifySrpSession -> mapOf("srpUserID" to srpUserId, "sessionID" to sessionId, "srpM1" to clientM1)
            is SendLoginOtp -> mapOf("email" to email, "purpose" to purpose)
            is VerifyEmail -> mapOf("email" to email, "ott" to otp)
            is VerifyTotp -> mapOf("sessionID" to sessionId, "code" to otp)
            is GetTokenForPasskeySession -> mapOf("sessionID" to sessionId)
        }

    override val headers: Map<String, String>? = null
}
