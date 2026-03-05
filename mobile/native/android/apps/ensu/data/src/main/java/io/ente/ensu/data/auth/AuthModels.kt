package io.ente.ensu.data.auth

data class SrpAttributes(
    val srpUserId: String,
    val srpSalt: String,
    val kekSalt: String,
    val memLimit: Int,
    val opsLimit: Int,
    val isEmailMfaEnabled: Boolean
)

data class KeyAttributes(
    val kekSalt: String,
    val encryptedKey: String,
    val keyDecryptionNonce: String,
    val publicKey: String,
    val encryptedSecretKey: String,
    val secretKeyDecryptionNonce: String,
    val memLimit: Int? = null,
    val opsLimit: Int? = null
)

data class AuthResponsePayload(
    val userId: Long,
    val keyAttributes: KeyAttributes?,
    val encryptedToken: String?,
    val token: String?,
    val twoFactorSessionId: String?,
    val passkeySessionId: String?,
    val accountsUrl: String?
) {
    val requiresTwoFactor: Boolean = !twoFactorSessionId.isNullOrBlank()
    val requiresPasskey: Boolean = !passkeySessionId.isNullOrBlank()
}

data class SrpLoginResult(
    val twoFactorSessionId: String?,
    val passkeySessionId: String?,
    val accountsUrl: String?
) {
    val requiresTwoFactor: Boolean = !twoFactorSessionId.isNullOrBlank()
    val requiresPasskey: Boolean = !passkeySessionId.isNullOrBlank()
}
