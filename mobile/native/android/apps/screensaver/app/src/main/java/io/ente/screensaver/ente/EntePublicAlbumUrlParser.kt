@file:Suppress("PackageDirectoryMismatch")

package io.ente.screensaver.ente

import android.net.Uri
import android.util.Base64
import java.math.BigInteger

object EntePublicAlbumUrlParser {

    sealed class ParseResult {
        data class Success(val config: EntePublicAlbumConfig) : ParseResult()

        data class Error(
            val code: Code,
            val detail: String? = null,
        ) : ParseResult() {

            enum class Code {
                EMPTY_URL,
                INVALID_URL,
                MISSING_ACCESS_TOKEN,
                MISSING_COLLECTION_KEY,
                INVALID_COLLECTION_KEY,
                INVALID_COLLECTION_KEY_LENGTH,
                FETCH_ALBUM_INFO_FAILED,
                MISSING_PASSWORD_PARAMETERS,
                PASSWORD_HASH_DERIVATION_FAILED,
                INCORRECT_PASSWORD,
                PASSWORD_VERIFICATION_FAILED,
                PASSWORD_REQUIRED,
            }

            fun debugMessage(): String {
                val suffix = detail?.takeIf { it.isNotBlank() }?.let { ": $it" }.orEmpty()
                return "${code.name}$suffix"
            }
        }
    }

    fun parsePublicUrl(publicUrl: String): ParseResult {
        val trimmed = publicUrl.trim()
        if (trimmed.isBlank()) {
            return ParseResult.Error(ParseResult.Error.Code.EMPTY_URL)
        }

        val uri = runCatching { Uri.parse(trimmed) }.getOrNull()
            ?: return ParseResult.Error(ParseResult.Error.Code.INVALID_URL)

        val accessToken = uri.getQueryParameter("t")?.trim()
            .takeIf { !it.isNullOrBlank() }
            ?: uri.pathSegments.firstOrNull()?.trim().takeIf { !it.isNullOrBlank() }
            ?: return ParseResult.Error(ParseResult.Error.Code.MISSING_ACCESS_TOKEN)

        val hash = uri.fragment?.trim().orEmpty()
        if (hash.isBlank()) {
            return ParseResult.Error(ParseResult.Error.Code.MISSING_COLLECTION_KEY)
        }

        val keyBytes = decodeCollectionKey(hash)
            ?: return ParseResult.Error(ParseResult.Error.Code.INVALID_COLLECTION_KEY)

        if (keyBytes.size != EnteCrypto.secretboxKeyBytes()) {
            return ParseResult.Error(ParseResult.Error.Code.INVALID_COLLECTION_KEY_LENGTH)
        }

        val collectionKeyB64 = Base64.encodeToString(keyBytes, Base64.NO_WRAP)

        return ParseResult.Success(
            EntePublicAlbumConfig(
                publicUrl = trimmed,
                accessToken = accessToken,
                collectionKeyB64 = collectionKeyB64,
            ),
        )
    }

    private const val BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    private fun decodeCollectionKey(input: String): ByteArray? {
        val trimmed = input.trim()
        if (trimmed.isBlank()) return null

        val withoutPrefix = trimmed.removePrefix("0x").removePrefix("0X")
        val looksHex = withoutPrefix.length == 64 &&
            withoutPrefix.all { it.isDigit() || it in 'a'..'f' || it in 'A'..'F' }

        if (trimmed.startsWith("0x") || trimmed.startsWith("0X") || looksHex) {
            return decodeHex(withoutPrefix)
        }

        return decodeBase58(trimmed) ?: decodeHex(withoutPrefix)
    }

    private fun decodeBase58(input: String): ByteArray? {
        if (input.isBlank()) return null
        var num = BigInteger.ZERO
        for (c in input) {
            val digit = BASE58_ALPHABET.indexOf(c)
            if (digit == -1) return null
            num = num.multiply(BigInteger.valueOf(58L)).add(BigInteger.valueOf(digit.toLong()))
        }

        var bytes = num.toByteArray()
        // BigInteger.toByteArray() uses two's-complement; strip sign byte.
        if (bytes.isNotEmpty() && bytes[0] == 0.toByte()) {
            bytes = bytes.copyOfRange(1, bytes.size)
        }

        val leadingZeros = input.takeWhile { it == '1' }.count()
        if (leadingZeros == 0) return bytes
        return ByteArray(leadingZeros) + bytes
    }

    private fun decodeHex(input: String): ByteArray? {
        val hex = input.removePrefix("0x").removePrefix("0X")
        if (hex.isBlank() || hex.length % 2 != 0) return null
        return try {
            ByteArray(hex.length / 2) { i ->
                val idx = i * 2
                hex.substring(idx, idx + 2).toInt(16).toByte()
            }
        } catch (_: Throwable) {
            null
        }
    }
}
