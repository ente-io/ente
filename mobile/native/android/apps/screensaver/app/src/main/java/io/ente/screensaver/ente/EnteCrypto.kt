package io.ente.screensaver.ente

import io.ente.screensaver.ente.uniffi.decryptBlobBytes as rustDecryptBlobBytes
import io.ente.screensaver.ente.uniffi.decryptBoxKey as rustDecryptBoxKey
import io.ente.screensaver.ente.uniffi.decryptMetadataFileType as rustDecryptMetadataFileType
import io.ente.screensaver.ente.uniffi.deriveKey as rustDeriveKey
import io.ente.screensaver.ente.uniffi.secretboxKeyBytes as rustSecretboxKeyBytes

object EnteCrypto {

    private val secretboxKeyBytesValue: Int by lazy { rustSecretboxKeyBytes().toInt() }

    fun secretboxKeyBytes(): Int = secretboxKeyBytesValue

    fun decryptBoxKey(
        encryptedKeyB64: String,
        keyDecryptionNonceB64: String,
        collectionKeyB64: String,
    ): ByteArray = rustDecryptBoxKey(encryptedKeyB64, keyDecryptionNonceB64, collectionKeyB64)

    fun deriveKey(
        passphrase: String,
        saltB64: String,
        opsLimit: Long,
        memLimit: Long,
    ): String {
        require(opsLimit >= 0L) { "opsLimit must be non-negative" }
        require(memLimit >= 0L) { "memLimit must be non-negative" }
        return rustDeriveKey(passphrase, saltB64, opsLimit.toULong(), memLimit.toULong())
    }

    fun decryptBlobBytes(
        encryptedData: ByteArray,
        decryptionHeaderB64: String,
        key: ByteArray,
    ): ByteArray = rustDecryptBlobBytes(encryptedData, decryptionHeaderB64, key)

    fun decryptMetadataFileType(
        encryptedDataB64: String,
        decryptionHeaderB64: String,
        key: ByteArray,
    ): Int? = rustDecryptMetadataFileType(encryptedDataB64, decryptionHeaderB64, key)
}
