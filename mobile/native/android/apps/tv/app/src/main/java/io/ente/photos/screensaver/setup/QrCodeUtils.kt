package io.ente.photos.screensaver.setup

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.ente.photos.screensaver.R
import qrcode.QRCode
import qrcode.color.Colors
import qrcode.color.QRCodeColorFunction
import qrcode.internals.QRCodeSquare
import qrcode.internals.QRCodeSquareType
import qrcode.raw.ErrorCorrectionLevel
import qrcode.render.QRCodeGraphics
import java.io.ByteArrayOutputStream

object QrCodeUtils {

    private const val LOGO_SIZE_RATIO = 0.10f
    private const val DENSE_PAYLOAD_LOGO_RATIO = 0.08f
    private const val DENSE_PAYLOAD_THRESHOLD = 72
    private const val EXAMPLE_CELL_SIZE = 13

    private val BLACK = Colors.css("#000000")
    private val FINDER_GREEN = Colors.css("#08C225")

    private var rawLogoBitmap: Bitmap? = null

    private val setupColorFunction = object : QRCodeColorFunction {
        override fun colorFn(square: QRCodeSquare, qrCode: QRCode, qrCodeGraphics: QRCodeGraphics): Int {
            if (!square.dark) return Colors.TRANSPARENT
            return if (square.squareInfo.type == QRCodeSquareType.POSITION_PROBE) FINDER_GREEN else BLACK
        }

        override fun beforeRender(qrCode: QRCode, qrCodeGraphics: QRCodeGraphics) = Unit

        override fun fg(x: Int, y: Int, qrCode: QRCode, qrCodeGraphics: QRCodeGraphics): Int {
            val type = squareTypeAt(qrCode, x, y)
            return if (type == QRCodeSquareType.POSITION_PROBE) FINDER_GREEN else BLACK
        }

        override fun bg(x: Int, y: Int, qrCode: QRCode, qrCodeGraphics: QRCodeGraphics): Int = Colors.TRANSPARENT

        override fun margin(x: Int, y: Int, qrCode: QRCode, qrCodeGraphics: QRCodeGraphics): Int = Colors.TRANSPARENT
    }

    fun renderQrCode(
        context: Context,
        text: String,
        sizePx: Int,
    ): Bitmap {
        if (text.isBlank() || sizePx <= 0) {
            return Bitmap.createBitmap(maxOf(1, sizePx), maxOf(1, sizePx), Bitmap.Config.ARGB_8888)
        }

        val logoRatio = if (text.length >= DENSE_PAYLOAD_THRESHOLD) DENSE_PAYLOAD_LOGO_RATIO else LOGO_SIZE_RATIO
        val targetLogoPx = (sizePx * logoRatio).toInt().coerceAtLeast(16)
        val logoBytes = scaledLogoBytes(context, targetLogoPx)
        val hasLogo = logoBytes.isNotEmpty()
        val profiles = listOf(
            BuildProfile(6, ErrorCorrectionLevel.VERY_HIGH, includeLogo = hasLogo),
            BuildProfile(8, ErrorCorrectionLevel.HIGH, includeLogo = hasLogo),
            BuildProfile(10, ErrorCorrectionLevel.HIGH, includeLogo = hasLogo, forceDensity = true),
            BuildProfile(11, ErrorCorrectionLevel.MEDIUM, includeLogo = hasLogo, forceDensity = true),
            BuildProfile(12, ErrorCorrectionLevel.MEDIUM, includeLogo = false, forceDensity = true),
        )

        var qrCode: QRCode? = null
        for (profile in profiles) {
            qrCode = buildQrCode(text, profile, logoBytes, targetLogoPx)
            if (qrCode != null) break
        }
        qrCode ?: return Bitmap.createBitmap(maxOf(1, sizePx), maxOf(1, sizePx), Bitmap.Config.ARGB_8888)

        val rendered = qrCode.render().nativeImage() as Bitmap
        return if (rendered.width == sizePx && rendered.height == sizePx) {
            rendered
        } else {
            Bitmap.createScaledBitmap(rendered, sizePx, sizePx, true)
        }
    }

    private data class BuildProfile(
        val density: Int,
        val correctionLevel: ErrorCorrectionLevel,
        val includeLogo: Boolean,
        val forceDensity: Boolean = false,
    )

    private fun buildQrCode(
        text: String,
        profile: BuildProfile,
        logoBytes: ByteArray,
        logoSizePx: Int,
    ): QRCode? {
        return runCatching {
            var builder = QRCode.ofCircles()
                .withSize(EXAMPLE_CELL_SIZE)
                .withCustomColorFunction(setupColorFunction)
                .withInformationDensity(profile.density)
                .withErrorCorrectionLevel(profile.correctionLevel)

            if (profile.forceDensity) {
                builder = builder.forceInformationDensity(true)
            }
            if (profile.includeLogo) {
                builder = builder.withLogo(logoBytes, logoSizePx, logoSizePx)
            }
            builder.build(text)
        }.getOrNull()
    }

    private fun squareTypeAt(qrCode: QRCode, row: Int, col: Int): QRCodeSquareType? {
        val rows = qrCode.rawData
        if (row !in rows.indices) return null

        val rowData = rows[row]
        if (col !in rowData.indices) return null

        return rowData[col].squareInfo.type
    }

    private fun scaledLogoBytes(context: Context, targetPx: Int): ByteArray {
        val source = rawLogoBitmap ?: BitmapFactory.decodeResource(context.resources, R.drawable.ente_qr_logo)?.also {
            rawLogoBitmap = it
        } ?: return ByteArray(0)

        val sized = if (source.width == targetPx && source.height == targetPx) {
            source
        } else {
            Bitmap.createScaledBitmap(source, targetPx, targetPx, true)
        }

        return ByteArrayOutputStream().use { baos ->
            sized.compress(Bitmap.CompressFormat.PNG, 100, baos)
            baos.toByteArray()
        }
    }
}
