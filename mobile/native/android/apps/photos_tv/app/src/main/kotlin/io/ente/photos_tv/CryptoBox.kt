@file:OptIn(ExperimentalUnsignedTypes::class)

package io.ente.photos_tv
import android.util.Base64
import io.ente.ensu.crypto.blobDecryptLegacy as rustBlobDecryptLegacy
import io.ente.ensu.crypto.generateKeyPair as rustGenerateKeyPair
import io.ente.ensu.crypto.openSeal as rustOpenSeal
import io.ente.ensu.crypto.secretboxDecrypt as rustSecretboxDecrypt
import io.ente.ensu.crypto.uniffiEnsureInitialized

internal class CryptoBox {
    init {
        uniffiEnsureInitialized()
    }

    fun generateKeyPair(): RegistrationKeyPair {
        val keyPair = rustGenerateKeyPair()
        return RegistrationKeyPair(
            publicKey = keyPair.publicKey.toByteArray(),
            privateKey = keyPair.privateKey.toByteArray(),
        )
    }

    fun openSeal(input: ByteArray, publicKey: ByteArray, privateKey: ByteArray): ByteArray {
        return rustOpenSeal(input.toUByteList(), publicKey.toUByteList(), privateKey.toUByteList()).toByteArray()
    }

    fun decrypt(input: ByteArray, key: ByteArray, nonce: ByteArray): ByteArray {
        return rustSecretboxDecrypt(input.toUByteList(), key.toUByteList(), nonce.toUByteList()).toByteArray()
    }

    fun decryptData(input: ByteArray, key: ByteArray, header: ByteArray): ByteArray {
        return rustBlobDecryptLegacy(input.toUByteList(), key.toUByteList(), header.toUByteList()).toByteArray()
    }

    fun base64(input: ByteArray): String {
        return Base64.encodeToString(input, Base64.NO_WRAP)
    }

    fun base64Decode(input: String): ByteArray {
        return Base64.decode(input, Base64.DEFAULT)
    }
}

private fun ByteArray.toUByteList(): List<UByte> {
    return toUByteArray().asList()
}

private fun List<UByte>.toByteArray(): ByteArray {
    return toUByteArray().toByteArray()
}

internal data class RegistrationKeyPair(
    val publicKey: ByteArray,
    val privateKey: ByteArray,
)
