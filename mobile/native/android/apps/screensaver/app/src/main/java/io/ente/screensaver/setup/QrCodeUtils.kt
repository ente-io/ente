@file:Suppress("PackageDirectoryMismatch")

package io.ente.photos.screensaver.setup

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import androidx.annotation.DrawableRes
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import com.google.zxing.qrcode.encoder.Encoder
import kotlin.math.max
import kotlin.math.min

object QrCodeUtils {

    private const val FINDER_SIZE_MODULES = 7
    private const val QUIET_ZONE_MODULES = 2

    private const val QR_DOT_COLOR = "#101114"
    private const val FINDER_GREEN = "#08C225"

    fun renderQrCode(
        context: Context,
        text: String,
        sizePx: Int,
        @DrawableRes centerLogoResId: Int,
    ): Bitmap {
        val hints = mapOf(
            EncodeHintType.MARGIN to 0,
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.H,
            EncodeHintType.CHARACTER_SET to "UTF-8",
        )

        val qrCode = Encoder.encode(text, ErrorCorrectionLevel.H, hints)
        val matrix = qrCode.matrix
        val moduleCount = matrix.width
        val totalModules = moduleCount + (QUIET_ZONE_MODULES * 2)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT)

        val moduleSize = sizePx / totalModules.toFloat()
        val dotRadius = moduleSize * 0.46f

        val modulePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(QR_DOT_COLOR)
            style = Paint.Style.FILL
        }

        val finderTopLeftX = QUIET_ZONE_MODULES
        val finderTopLeftY = QUIET_ZONE_MODULES
        val finderTopRightX = QUIET_ZONE_MODULES + moduleCount - FINDER_SIZE_MODULES
        val finderBottomLeftY = QUIET_ZONE_MODULES + moduleCount - FINDER_SIZE_MODULES

        val finderRects = listOf(
            FinderRect(finderTopLeftX, finderTopLeftY),
            FinderRect(finderTopRightX, finderTopLeftY),
            FinderRect(finderTopLeftX, finderBottomLeftY),
        )

        val qrCenterModules = QUIET_ZONE_MODULES + moduleCount / 2f
        val logoCutoutRadiusModules = max(4f, moduleCount * 0.10f)

        for (y in 0 until moduleCount) {
            for (x in 0 until moduleCount) {
                if (matrix.get(x, y).toInt() != 1) continue

                val drawX = x + QUIET_ZONE_MODULES
                val drawY = y + QUIET_ZONE_MODULES

                if (finderRects.any { it.contains(drawX, drawY) }) continue

                val moduleCenterX = drawX + 0.5f
                val moduleCenterY = drawY + 0.5f
                val dx = moduleCenterX - qrCenterModules
                val dy = moduleCenterY - qrCenterModules
                if (dx * dx + dy * dy <= logoCutoutRadiusModules * logoCutoutRadiusModules) continue

                val centerX = moduleCenterX * moduleSize
                val centerY = moduleCenterY * moduleSize
                canvas.drawCircle(centerX, centerY, dotRadius, modulePaint)
            }
        }

        finderRects.forEach { finder ->
            drawFinderPattern(
                canvas = canvas,
                moduleSize = moduleSize,
                startX = finder.startX,
                startY = finder.startY,
            )
        }

        drawCenterLogo(
            context = context,
            canvas = canvas,
            sizePx = sizePx,
            moduleSize = moduleSize,
            logoCutoutRadiusModules = logoCutoutRadiusModules,
            centerLogoResId = centerLogoResId,
        )

        return bitmap
    }

    private fun drawFinderPattern(
        canvas: Canvas,
        moduleSize: Float,
        startX: Int,
        startY: Int,
    ) {
        val left = startX * moduleSize
        val top = startY * moduleSize
        val size = FINDER_SIZE_MODULES * moduleSize
        val right = left + size
        val bottom = top + size

        val outerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(FINDER_GREEN)
            style = Paint.Style.FILL
        }
        val innerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val centerDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            style = Paint.Style.FILL
        }

        val outerRadius = size * 0.26f
        canvas.drawRoundRect(RectF(left, top, right, bottom), outerRadius, outerRadius, outerPaint)

        val ringThickness = size * 0.22f
        val innerRect = RectF(
            left + ringThickness,
            top + ringThickness,
            right - ringThickness,
            bottom - ringThickness,
        )
        val innerRadius = innerRect.width() * 0.25f
        canvas.drawRoundRect(innerRect, innerRadius, innerRadius, innerPaint)

        val centerDotRadius = size * 0.14f
        canvas.drawCircle(left + size / 2f, top + size / 2f, centerDotRadius, centerDotPaint)
    }

    private fun drawCenterLogo(
        context: Context,
        canvas: Canvas,
        sizePx: Int,
        moduleSize: Float,
        logoCutoutRadiusModules: Float,
        @DrawableRes centerLogoResId: Int,
    ) {
        val logoBitmap = BitmapFactory.decodeResource(context.resources, centerLogoResId) ?: return

        val cutoutDiameterPx = logoCutoutRadiusModules * moduleSize * 2f
        val logoSize = min(sizePx * 0.17f, cutoutDiameterPx * 0.82f)

        val cx = sizePx / 2f
        val cy = sizePx / 2f

        val halfLogo = logoSize / 2f
        val destination = RectF(
            cx - halfLogo,
            cy - halfLogo,
            cx + halfLogo,
            cy + halfLogo,
        )
        canvas.drawBitmap(logoBitmap, null, destination, null)
    }

    private data class FinderRect(
        val startX: Int,
        val startY: Int,
    ) {
        fun contains(x: Int, y: Int): Boolean {
            return x in startX until (startX + FINDER_SIZE_MODULES) &&
                y in startY until (startY + FINDER_SIZE_MODULES)
        }
    }
}
