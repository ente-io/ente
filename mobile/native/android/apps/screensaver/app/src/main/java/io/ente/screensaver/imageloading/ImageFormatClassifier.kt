package io.ente.screensaver.imageloading

import android.net.Uri
import java.io.File

object ImageFormatClassifier {

    enum class Family {
        JPEG,
        PNG,
        APNG,
        GIF,
        WEBP,
        WEBP_ANIMATED,
        SVG,
        AVIF,
        HEIC,
        HEIF,
        BMP,
        JXL,
        TIFF,
        RAW,
        UNKNOWN_IMAGE,
        NON_IMAGE,
    }

    data class Result(
        val family: Family,
        val mimeType: String?,
        val extension: String?,
        val isAnimated: Boolean,
        val isVector: Boolean,
        val isRaw: Boolean,
        val isImage: Boolean,
    )

    val supportedImageExtensions: List<String> = listOf(
        ".jpg",
        ".jpeg",
        ".png",
        ".bmp",
        ".webp",
        ".heic",
        ".heif",
        ".apng",
        ".avif",
        ".jxl",
        ".gif",
        ".svg",
        ".dng",
        ".orf",
        ".nef",
        ".arw",
        ".rw2",
        ".cr2",
        ".cr3",
        ".tif",
        ".tiff",
    )

    val rawExtensions: Set<String> = setOf(
        "dng",
        "orf",
        "nef",
        "arw",
        "rw2",
        "cr2",
        "cr3",
    )

    val displaySupportedMimes: Set<String> = setOf(
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/gif",
        "image/bmp",
        "image/x-ms-bmp",
        "image/heic",
        "image/heif",
        "image/avif",
        "image/apng",
        "image/svg+xml",
        "image/jxl",
        "image/tiff",
        "image/x-adobe-dng",
        "image/x-canon-cr2",
        "image/x-canon-cr3",
        "image/x-fuji-raf",
        "image/x-nikon-nef",
        "image/x-olympus-orf",
        "image/x-panasonic-rw2",
        "image/x-pentax-pef",
        "image/x-sony-arw",
        "image/x-sigma-x3f",
    )

    val neverTranscodeMimes: Set<String> = setOf(
        "image/gif",
        "image/apng",
        "image/svg+xml",
        "image/jxl",
        "image/x-adobe-dng",
        "image/x-canon-cr2",
        "image/x-canon-cr3",
        "image/x-fuji-raf",
        "image/x-nikon-nef",
        "image/x-olympus-orf",
        "image/x-panasonic-rw2",
        "image/x-pentax-pef",
        "image/x-sony-arw",
        "image/x-sigma-x3f",
    )

    fun extensionFromUri(uri: Uri?): String? {
        val path = uri?.path.orEmpty()
        val dot = path.lastIndexOf('.')
        if (dot < 0 || dot == path.lastIndex) return null
        return path.substring(dot + 1).lowercase()
    }

    fun classify(
        uri: Uri? = null,
        mimeType: String? = null,
        headerBytes: ByteArray? = null,
    ): Result {
        val ext = extensionFromUri(uri)
        val sniffedMime = headerBytes?.let { sniffMime(it) }
        val normalizedMime = resolveMime(mimeType, headerBytes) ?: sniffedMime ?: mimeFromExtension(ext)

        val family = familyFrom(normalizedMime, ext, headerBytes)
        val animated = family == Family.GIF || family == Family.APNG || family == Family.WEBP_ANIMATED
        val vector = family == Family.SVG
        val raw = family == Family.RAW
        val image = family != Family.NON_IMAGE

        return Result(
            family = family,
            mimeType = normalizedMime,
            extension = ext,
            isAnimated = animated,
            isVector = vector,
            isRaw = raw,
            isImage = image,
        )
    }

    fun resolveMime(maybeMime: String?, bytes: ByteArray?): String? {
        val normalized = maybeMime?.lowercase().orEmpty()
        if (normalized.isNotBlank()) {
            if (normalized == "image/png" && bytes != null && isAnimatedPng(bytes)) {
                return "image/apng"
            }
            if (normalized == "image/webp" && bytes != null && isAnimatedWebp(bytes)) {
                return "image/webp"
            }
            return normalized
        }
        return bytes?.let { sniffMime(it) }
    }

    fun detectMime(file: File, maxBytes: Int = 256 * 1024): String? {
        val head = readHead(file, maxBytes) ?: return null
        return sniffMime(head)
    }

    fun readHead(file: File, maxBytes: Int = 256 * 1024): ByteArray? {
        return runCatching {
            if (!file.exists() || file.length() <= 0L) return@runCatching null
            file.inputStream().use { stream ->
                val buffer = ByteArray(maxBytes)
                val read = stream.read(buffer)
                if (read <= 0) null else buffer.copyOf(read)
            }
        }.getOrNull()
    }

    fun sniffMime(bytes: ByteArray): String? {
        if (bytes.size >= 3 && bytes[0] == 0xFF.toByte() && bytes[1] == 0xD8.toByte() && bytes[2] == 0xFF.toByte()) {
            return "image/jpeg"
        }

        if (hasPngSignature(bytes)) {
            return if (isAnimatedPng(bytes)) "image/apng" else "image/png"
        }

        if (bytes.size >= 6) {
            val gifHeader = readAscii(bytes, 0, 6)
            if (gifHeader == "GIF87a" || gifHeader == "GIF89a") {
                return "image/gif"
            }
        }

        if (bytes.size >= 12 &&
            readAscii(bytes, 0, 4) == "RIFF" &&
            readAscii(bytes, 8, 4) == "WEBP"
        ) {
            return "image/webp"
        }

        if (bytes.size >= 2 && bytes[0] == 'B'.code.toByte() && bytes[1] == 'M'.code.toByte()) {
            return "image/bmp"
        }

        if (bytes.size >= 4) {
            val littleTiff = bytes[0] == 'I'.code.toByte() &&
                bytes[1] == 'I'.code.toByte() &&
                bytes[2] == 0x2A.toByte() &&
                bytes[3] == 0x00.toByte()
            val bigTiff = bytes[0] == 'M'.code.toByte() &&
                bytes[1] == 'M'.code.toByte() &&
                bytes[2] == 0x00.toByte() &&
                bytes[3] == 0x2A.toByte()
            if (littleTiff || bigTiff) {
                if (looksLikeCr2(bytes)) return "image/x-canon-cr2"
                return "image/tiff"
            }
        }

        detectIsoBmffMime(bytes)?.let { return it }

        if (bytes.size >= 2 && bytes[0] == 0xFF.toByte() && bytes[1] == 0x0A.toByte()) {
            return "image/jxl"
        }

        if (bytes.size >= 12 &&
            bytes[0] == 0x00.toByte() &&
            bytes[1] == 0x00.toByte() &&
            bytes[2] == 0x00.toByte() &&
            bytes[3] == 0x0C.toByte() &&
            readAscii(bytes, 4, 4) == "JXL "
        ) {
            return "image/jxl"
        }

        if (looksLikeSvg(bytes)) {
            return "image/svg+xml"
        }

        return null
    }

    fun hasPngSignature(bytes: ByteArray): Boolean {
        if (bytes.size < 8) return false
        return bytes[0] == 0x89.toByte() &&
            bytes[1] == 0x50.toByte() &&
            bytes[2] == 0x4E.toByte() &&
            bytes[3] == 0x47.toByte() &&
            bytes[4] == 0x0D.toByte() &&
            bytes[5] == 0x0A.toByte() &&
            bytes[6] == 0x1A.toByte() &&
            bytes[7] == 0x0A.toByte()
    }

    fun isAnimatedPng(bytes: ByteArray): Boolean {
        if (!hasPngSignature(bytes)) return false
        val needle = byteArrayOf('a'.code.toByte(), 'c'.code.toByte(), 'T'.code.toByte(), 'L'.code.toByte())
        return indexOfBytes(bytes, needle, start = 8, endExclusive = bytes.size.coerceAtMost(256 * 1024)) >= 0
    }

    fun isAnimatedWebp(bytes: ByteArray): Boolean {
        if (bytes.size < 12) return false
        if (readAscii(bytes, 0, 4) != "RIFF" || readAscii(bytes, 8, 4) != "WEBP") return false
        val animChunk = byteArrayOf('A'.code.toByte(), 'N'.code.toByte(), 'I'.code.toByte(), 'M'.code.toByte())
        return indexOfBytes(bytes, animChunk, start = 12, endExclusive = bytes.size.coerceAtMost(256 * 1024)) >= 0
    }

    fun looksLikeSvg(bytes: ByteArray): Boolean {
        if (bytes.isEmpty()) return false
        val text = runCatching { bytes.copyOf(bytes.size.coerceAtMost(1024)).toString(Charsets.UTF_8) }.getOrNull()
            ?: return false
        val normalized = text.trimStart('\uFEFF', ' ', '\n', '\r', '\t').lowercase()
        return normalized.startsWith("<svg") ||
            (normalized.startsWith("<?xml") && normalized.contains("<svg"))
    }

    private fun familyFrom(mime: String?, ext: String?, headerBytes: ByteArray?): Family {
        val normalized = mime?.lowercase().orEmpty()
        if (normalized.isNotBlank()) {
            return when {
                normalized == "image/jpeg" || normalized == "image/jpg" -> Family.JPEG
                normalized == "image/png" -> if (headerBytes != null && isAnimatedPng(headerBytes)) Family.APNG else Family.PNG
                normalized == "image/apng" -> Family.APNG
                normalized == "image/gif" -> Family.GIF
                normalized == "image/webp" -> if (headerBytes != null && isAnimatedWebp(headerBytes)) Family.WEBP_ANIMATED else Family.WEBP
                normalized == "image/svg+xml" -> Family.SVG
                normalized == "image/avif" -> Family.AVIF
                normalized == "image/heic" -> Family.HEIC
                normalized == "image/heif" -> Family.HEIF
                normalized == "image/bmp" || normalized == "image/x-ms-bmp" -> Family.BMP
                normalized == "image/jxl" -> Family.JXL
                normalized == "image/tiff" -> Family.TIFF
                normalized in rawMimes -> Family.RAW
                normalized.startsWith("image/") -> Family.UNKNOWN_IMAGE
                else -> Family.NON_IMAGE
            }
        }

        return when (ext) {
            "jpg", "jpeg" -> Family.JPEG
            "png" -> Family.PNG
            "apng" -> Family.APNG
            "gif" -> Family.GIF
            "webp" -> Family.WEBP
            "svg" -> Family.SVG
            "avif" -> Family.AVIF
            "heic" -> Family.HEIC
            "heif" -> Family.HEIF
            "bmp" -> Family.BMP
            "jxl" -> Family.JXL
            "tif", "tiff" -> Family.TIFF
            in rawExtensions -> Family.RAW
            null -> Family.UNKNOWN_IMAGE
            else -> Family.UNKNOWN_IMAGE
        }
    }

    private fun mimeFromExtension(ext: String?): String? {
        return when (ext) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "apng" -> "image/apng"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "svg" -> "image/svg+xml"
            "avif" -> "image/avif"
            "heic" -> "image/heic"
            "heif" -> "image/heif"
            "bmp" -> "image/bmp"
            "jxl" -> "image/jxl"
            "tif", "tiff" -> "image/tiff"
            "dng" -> "image/x-adobe-dng"
            "cr2" -> "image/x-canon-cr2"
            "cr3" -> "image/x-canon-cr3"
            "nef" -> "image/x-nikon-nef"
            "orf" -> "image/x-olympus-orf"
            "arw" -> "image/x-sony-arw"
            "rw2" -> "image/x-panasonic-rw2"
            else -> null
        }
    }

    private fun detectIsoBmffMime(bytes: ByteArray): String? {
        if (bytes.size < 12) return null
        if (readAscii(bytes, 4, 4) != "ftyp") return null

        val majorBrand = readAscii(bytes, 8, 4).lowercase()
        val compatBrands = mutableListOf<String>()
        var index = 16
        val max = bytes.size.coerceAtMost(128)
        while (index + 4 <= max) {
            compatBrands.add(readAscii(bytes, index, 4).lowercase())
            index += 4
        }

        val brands = buildList {
            add(majorBrand)
            addAll(compatBrands)
        }

        if (brands.any { it.startsWith("avif") || it.startsWith("avis") }) return "image/avif"
        if (brands.any { it.startsWith("heic") || it.startsWith("heix") }) return "image/heic"
        if (brands.any { it.startsWith("heif") || it.startsWith("hevc") || it.startsWith("hevx") || it == "mif1" }) {
            return "image/heif"
        }
        if (brands.any { it.startsWith("crx") || it.startsWith("cr3") }) return "image/x-canon-cr3"
        if (brands.any { it in setOf("isom", "iso2", "mp41", "mp42", "m4v ", "3gp4", "3gp5", "qt  ") }) {
            return "video/mp4"
        }
        return null
    }

    private fun looksLikeCr2(bytes: ByteArray): Boolean {
        if (bytes.size < 12) return false
        return (bytes[8] == 'C'.code.toByte() && bytes[9] == 'R'.code.toByte())
    }

    private fun indexOfBytes(
        haystack: ByteArray,
        needle: ByteArray,
        start: Int = 0,
        endExclusive: Int = haystack.size,
    ): Int {
        if (needle.isEmpty()) return start
        val end = (endExclusive - needle.size).coerceAtLeast(start)
        for (i in start..end) {
            var match = true
            for (j in needle.indices) {
                if (haystack[i + j] != needle[j]) {
                    match = false
                    break
                }
            }
            if (match) return i
        }
        return -1
    }

    private fun readAscii(bytes: ByteArray, start: Int, length: Int): String {
        if (start < 0 || length <= 0 || start + length > bytes.size) return ""
        return buildString(length) {
            for (i in start until (start + length)) {
                append((bytes[i].toInt() and 0xFF).toChar())
            }
        }
    }

    private val rawMimes = setOf(
        "image/x-adobe-dng",
        "image/x-canon-cr2",
        "image/x-canon-cr3",
        "image/x-fuji-raf",
        "image/x-nikon-nef",
        "image/x-olympus-orf",
        "image/x-panasonic-rw2",
        "image/x-pentax-pef",
        "image/x-sony-arw",
        "image/x-sigma-x3f",
    )
}
