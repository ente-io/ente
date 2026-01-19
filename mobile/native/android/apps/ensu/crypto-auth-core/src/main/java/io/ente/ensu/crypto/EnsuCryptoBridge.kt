@file:OptIn(ExperimentalUnsignedTypes::class)

package io.ente.ensu.crypto

object EnsuCryptoBridge {
    init {
        uniffiEnsureInitialized()
    }

    fun init() {
        io.ente.ensu.crypto.initCrypto()
    }

    fun srpStart(password: String, attrs: SrpAttributes): SrpSessionResult {
        return io.ente.ensu.crypto.srpStart(password, attrs)
    }

    fun srpFinish(srpB: String): SrpVerifyResult {
        return io.ente.ensu.crypto.srpFinish(srpB)
    }

    fun srpClear() {
        io.ente.ensu.crypto.srpClear()
    }

    fun srpDecryptSecrets(
        keyAttributes: KeyAttributes,
        encryptedToken: String?,
        plainToken: String?
    ): AuthSecrets {
        return io.ente.ensu.crypto.srpDecryptSecrets(keyAttributes, encryptedToken, plainToken)
    }

    fun deriveKekForLogin(password: String, kekSalt: String, memLimit: Int, opsLimit: Int): ByteArray {
        val result = io.ente.ensu.crypto.deriveKekForLogin(password, kekSalt, memLimit.toUInt(), opsLimit.toUInt())
        return result.toUByteArray().toByteArray()
    }

    fun decryptSecretsWithKek(
        kek: ByteArray,
        keyAttributes: KeyAttributes,
        encryptedToken: String?,
        plainToken: String?
    ): AuthSecrets {
        val kekList = kek.toUByteArray().asList()
        return io.ente.ensu.crypto.decryptSecretsWithKek(kekList, keyAttributes, encryptedToken, plainToken)
    }
}
