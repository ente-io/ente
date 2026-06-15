package io.ente.photos_tv

import com.goterl.lazysodium.LazySodiumAndroid
import com.goterl.lazysodium.SodiumAndroid
import com.goterl.lazysodium.exceptions.SodiumException
import com.goterl.lazysodium.interfaces.Box
import com.goterl.lazysodium.interfaces.SecretBox
import com.goterl.lazysodium.interfaces.SecretStream
import android.util.Base64

internal class CryptoBox {
    private val sodium = LazySodiumAndroid(SodiumAndroid())

    fun generateKeyPair(): RegistrationKeyPair {
        val keyPair = sodium.cryptoBoxKeypair()
        return RegistrationKeyPair(
            publicKey = keyPair.publicKey.asBytes,
            privateKey = keyPair.secretKey.asBytes,
        )
    }

    fun openSeal(input: ByteArray, publicKey: ByteArray, privateKey: ByteArray): ByteArray {
        require(input.size >= Box.SEALBYTES) { "crypto_box_seal ciphertext too short: ${input.size}" }
        val output = ByteArray(input.size - Box.SEALBYTES)
        val success = sodium.cryptoBoxSealOpen(output, input, input.size.toLong(), publicKey, privateKey)
        if (!success) throw SodiumException("crypto_box_seal_open")
        return output
    }

    fun decrypt(input: ByteArray, key: ByteArray, nonce: ByteArray): ByteArray {
        require(input.size >= SecretBox.MACBYTES) { "crypto_secretbox ciphertext too short: ${input.size}" }
        val output = ByteArray(input.size - SecretBox.MACBYTES)
        val success = sodium.cryptoSecretBoxOpenEasy(output, input, input.size.toLong(), nonce, key)
        if (!success) throw SodiumException("crypto_secretbox_open_easy")
        return output
    }

    fun decryptData(input: ByteArray, key: ByteArray, header: ByteArray): ByteArray {
        val state = SecretStreamState(sodium, header, key)
        return state.pullAll(input)
    }

    fun base64(input: ByteArray): String {
        return Base64.encodeToString(input, Base64.NO_WRAP)
    }

    fun base64Decode(input: String): ByteArray {
        return Base64.decode(input, Base64.DEFAULT)
    }
}

internal data class RegistrationKeyPair(
    val publicKey: ByteArray,
    val privateKey: ByteArray,
)

private class SecretStreamState(
    private val sodium: LazySodiumAndroid,
    private val header: ByteArray,
    private val key: ByteArray,
) {
    fun pullAll(input: ByteArray): ByteArray {
        require(input.size >= SecretStream.ABYTES) { "crypto_secretstream ciphertext too short: ${input.size}" }
        val state = SecretStream.State()
        val initSuccess = sodium.cryptoSecretStreamInitPull(state, header, key)
        if (!initSuccess) throw SodiumException("crypto_secretstream_xchacha20poly1305_init_pull")
        val output = ByteArray(input.size - SecretStream.ABYTES)
        val tag = ByteArray(1)
        val outLength = LongArray(1)
        val pullSuccess = sodium.cryptoSecretStreamPull(state, output, outLength, tag, input, input.size.toLong(), ByteArray(0), 0)
        if (!pullSuccess) throw SodiumException("crypto_secretstream_xchacha20poly1305_pull")
        return output.copyOf(outLength[0].toInt())
    }
}
