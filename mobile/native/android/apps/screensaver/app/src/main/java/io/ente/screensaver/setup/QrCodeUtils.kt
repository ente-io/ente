package io.ente.photos.screensaver.setup

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import kotlin.math.min

object QrCodeUtils {

    fun renderQrCode(text: String, sizePx: Int): Bitmap {
        val modules = 120
        val hints = mapOf(
            EncodeHintType.MARGIN to 1,
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.H,
        )
        val matrix = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, modules, modules, hints)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)

        val moduleSize = sizePx / modules.toFloat()
        val radius = min(moduleSize * 0.45f, 8f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            style = Paint.Style.FILL
        }

        for (y in 0 until modules) {
            for (x in 0 until modules) {
                if (!matrix.get(x, y)) continue
                val left = x * moduleSize
                val top = y * moduleSize
                val right = left + moduleSize
                val bottom = top + moduleSize
                canvas.drawRoundRect(RectF(left, top, right, bottom), radius, radius, paint)
            }
        }

        return bitmap
    }
}
