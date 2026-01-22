@file:OptIn(ExperimentalUnsignedTypes::class)

package io.ente.ensu.data.auth

import android.content.Context
import android.util.Base64
import io.ente.ensu.crypto.AuthSecrets
import io.ente.ensu.crypto.EnsuCryptoBridge
import io.ente.ensu.crypto.KeyAttributes as CryptoKeyAttributes
import io.ente.ensu.crypto.SrpAttributes as CryptoSrpAttributes
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.network.ApiException
import io.ente.ensu.data.network.AuthorizationResponse
import io.ente.ensu.data.network.NetworkConfiguration
import io.ente.ensu.data.network.NetworkFactory
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogLevel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject

class EnsuAuthService(
    private val context: Context,
    private val endpointPreferences: EndpointPreferencesDataStore,
    private val credentialStore: CredentialStore,
    private val logRepository: LogRepository
) {
    private val authTokenProvider = EnsuAuthTokenProvider(credentialStore)
    private val okHttpClient = OkHttpClient()

    private var networkFactory = NetworkFactory(
        context = context,
        configuration = NetworkConfiguration.default,
        authTokenProvider = authTokenProvider
    )

    val currentEndpointFlow: Flow<String> = endpointPreferences.endpointFlow.map { endpoint ->
        endpoint ?: NetworkConfiguration.default.apiEndpoint.toString()
    }

    val storedEndpointFlow: Flow<String?> = endpointPreferences.endpointFlow

    init {
        runCatching { EnsuCryptoBridge.init() }
            .onFailure { error ->
                logRepository.log(
                    LogLevel.Error,
                    "Crypto init failed",
                    details = error.message,
                    tag = "Auth",
                    throwable = error
                )
            }
            .getOrThrow()
    }

    suspend fun updateEndpoint(endpoint: String?) {
        val url = endpoint?.toHttpUrlOrNull()
        updateEndpointUrl(url)
    }

    private suspend fun updateEndpointUrl(endpoint: HttpUrl?) {
        val config = if (endpoint != null) {
            NetworkConfiguration.selfHosted(endpoint)
        } else {
            NetworkConfiguration.default
        }
        networkFactory = NetworkFactory(
            context = context,
            configuration = config,
            authTokenProvider = authTokenProvider
        )
    }

    suspend fun setEndpoint(endpointInput: String): Result<String> {
        val normalized = normalize(endpointInput)
        val url = normalized.toHttpUrlOrNull()
            ?: return Result.failure(IllegalArgumentException("Invalid endpoint"))

        if (url.scheme != "http" && url.scheme != "https") {
            return Result.failure(IllegalArgumentException("Invalid endpoint"))
        }

        return try {
            pingEndpoint(url)
            endpointPreferences.setEndpoint(normalized)
            updateEndpointUrl(url)
            logRepository.log(LogLevel.Info, "Updated endpoint", details = normalized, tag = "Auth")
            Result.success(normalized)
        } catch (error: Exception) {
            logRepository.log(
                LogLevel.Error,
                "Endpoint update failed",
                details = error.message,
                tag = "Auth",
                throwable = error
            )
            Result.failure(error)
        }
    }

    suspend fun getSrpAttributes(email: String): SrpAttributes {
        val response = networkFactory.authentication.getSrpAttributes(email)
        return SrpAttributes(
            srpUserId = response.attributes.srpUserId,
            srpSalt = response.attributes.srpSalt,
            kekSalt = response.attributes.kekSalt,
            memLimit = response.attributes.memLimit,
            opsLimit = response.attributes.opsLimit,
            isEmailMfaEnabled = response.attributes.isEmailMfaEnabled
        )
    }

    suspend fun sendOtp(email: String) {
        networkFactory.authentication.sendLoginOtp(email)
    }

    suspend fun verifyOtp(email: String, otp: String): AuthResponsePayload {
        val response = networkFactory.authentication.verifyEmail(email, otp)
        return response.toPayload()
    }

    suspend fun verifyTwoFactor(sessionId: String, code: String): AuthResponsePayload {
        val response = networkFactory.authentication.verifyTotp(sessionId, code)
        return response.toPayload()
    }

    suspend fun getTokenForPasskeySession(sessionId: String): AuthResponsePayload {
        return try {
            val response = networkFactory.authentication.getTokenForPasskeySession(sessionId)
            response.toPayload()
        } catch (error: ApiException) {
            if (error.code == 400) throw PasskeySessionNotVerifiedException()
            if (error.code == 404 || error.code == 410) throw PasskeySessionExpiredException()
            throw error
        }
    }

    suspend fun loginWithSrp(email: String, password: String, srpAttributes: SrpAttributes): SrpLoginResult {
        try {
            logRepository.log(LogLevel.Info, "SRP login started", tag = "Auth")
            val start = withContext(Dispatchers.Default) {
                EnsuCryptoBridge.srpStart(password, srpAttributes.toCrypto())
            }

            val session = networkFactory.authentication.createSrpSession(
                srpUserId = srpAttributes.srpUserId,
                clientPub = start.srpA
            )

            val verify = withContext(Dispatchers.Default) {
                EnsuCryptoBridge.srpFinish(session.srpB)
            }

            val response = networkFactory.authentication.verifySrpSession(
                srpUserId = srpAttributes.srpUserId,
                sessionId = session.sessionId,
                clientM1 = verify.srpM1
            )

            val payload = response.toPayload()
            val passkeySessionId = payload.passkeySessionId?.takeIf { it.isNotBlank() }
            val twoFactorSessionId = payload.twoFactorSessionId?.takeIf { it.isNotBlank() }
            if (passkeySessionId != null || twoFactorSessionId != null) {
                return SrpLoginResult(
                    twoFactorSessionId = twoFactorSessionId,
                    passkeySessionId = passkeySessionId,
                    accountsUrl = payload.accountsUrl?.takeIf { it.isNotBlank() }
                        ?: networkFactory.configuration.accountsEndpoint?.toString()
                )
            }

            val keyAttributes = payload.keyAttributes ?: throw IllegalStateException("Invalid response")
            val secrets = withContext(Dispatchers.Default) {
                EnsuCryptoBridge.srpDecryptSecrets(
                    keyAttributes = keyAttributes.toCrypto(),
                    encryptedToken = payload.encryptedToken,
                    plainToken = payload.token
                )
            }

            storeSecrets(email, payload.userId, secrets)
            logRepository.log(LogLevel.Info, "SRP login success", tag = "Auth")
            return SrpLoginResult(null, null, null)
        } finally {
            EnsuCryptoBridge.srpClear()
        }
    }

    suspend fun loginAfterChallenge(
        email: String,
        password: String,
        srpAttributes: SrpAttributes,
        userId: Long,
        keyAttributes: KeyAttributes,
        encryptedToken: String?,
        token: String?
    ) {
        val kek = withContext(Dispatchers.Default) {
            EnsuCryptoBridge.deriveKekForLogin(
                password = password,
                kekSalt = srpAttributes.kekSalt,
                memLimit = srpAttributes.memLimit,
                opsLimit = srpAttributes.opsLimit
            )
        }

        val secrets = try {
            withContext(Dispatchers.Default) {
                EnsuCryptoBridge.decryptSecretsWithKek(
                    kek = kek,
                    keyAttributes = keyAttributes.toCrypto(),
                    encryptedToken = encryptedToken,
                    plainToken = token
                )
            }
        } finally {
            // Best-effort zeroing of sensitive material after use.
            kek.fill(0)
        }

        storeSecrets(email, userId, secrets)
        logRepository.log(LogLevel.Info, "Login after challenge success", tag = "Auth")
    }

    fun clearCredentials() {
        credentialStore.clear()
    }

    private suspend fun pingEndpoint(endpoint: HttpUrl) {
        withContext(Dispatchers.IO) {
            val url = endpoint.newBuilder().addPathSegment("ping").build()
            val request = Request.Builder().url(url).get().build()
            okHttpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IllegalStateException("Ping failed")
                }
                val body = response.body?.string().orEmpty()
                val json = JSONObject(body)
                if (json.optString("message") != "pong") {
                    throw IllegalStateException("Invalid ping response")
                }
            }
        }
    }

    private fun storeSecrets(email: String, userId: Long, secrets: AuthSecrets) {
        val masterKey = secrets.masterKey.toUByteArray().toByteArray()
        val secretKey = secrets.secretKey.toUByteArray().toByteArray()
        val tokenBytes = secrets.token.toUByteArray().toByteArray()
        val token = Base64.encodeToString(tokenBytes, Base64.NO_WRAP or Base64.URL_SAFE)

        credentialStore.save(email, userId, masterKey, secretKey, token)

        // Best-effort zeroing of sensitive material after persisting.
        masterKey.fill(0)
        secretKey.fill(0)
        tokenBytes.fill(0)
    }

    private fun normalize(value: String): String {
        var trimmed = value.trim()
        while (trimmed.endsWith("/")) {
            trimmed = trimmed.dropLast(1)
        }
        return trimmed
    }
}

class PasskeySessionNotVerifiedException : Exception()
class PasskeySessionExpiredException : Exception()

private fun SrpAttributes.toCrypto(): CryptoSrpAttributes {
    return CryptoSrpAttributes(
        srpUserId = srpUserId,
        srpSalt = srpSalt,
        kekSalt = kekSalt,
        memLimit = memLimit.toUInt(),
        opsLimit = opsLimit.toUInt(),
        isEmailMfaEnabled = isEmailMfaEnabled
    )
}

private fun KeyAttributes.toCrypto(): CryptoKeyAttributes {
    return CryptoKeyAttributes(
        kekSalt = kekSalt,
        encryptedKey = encryptedKey,
        keyDecryptionNonce = keyDecryptionNonce,
        publicKey = publicKey,
        encryptedSecretKey = encryptedSecretKey,
        secretKeyDecryptionNonce = secretKeyDecryptionNonce,
        memLimit = memLimit?.toUInt(),
        opsLimit = opsLimit?.toUInt()
    )
}

private fun AuthorizationResponse.toPayload(): AuthResponsePayload {
    val attrs = keyAttributes?.let {
        KeyAttributes(
            kekSalt = it.kekSalt,
            encryptedKey = it.encryptedKey,
            keyDecryptionNonce = it.keyDecryptionNonce,
            publicKey = it.publicKey,
            encryptedSecretKey = it.encryptedSecretKey,
            secretKeyDecryptionNonce = it.secretKeyDecryptionNonce,
            memLimit = it.memLimit,
            opsLimit = it.opsLimit
        )
    }
    return AuthResponsePayload(
        userId = id,
        keyAttributes = attrs,
        encryptedToken = encryptedToken,
        token = token,
        twoFactorSessionId = effectiveTwoFactorSessionId,
        passkeySessionId = passkeySessionId,
        accountsUrl = accountsUrl
    )
}
