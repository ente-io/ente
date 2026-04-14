package io.ente.auth.ente_auth_qr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader
import com.google.zxing.NotFoundException
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.Result as ZXingResult
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.multi.GenericMultipleBarcodeReader
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.*
import java.util.concurrent.Executors

/** EnteQrPlugin */
class EnteQrPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private val executor = Executors.newSingleThreadExecutor()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ente_qr")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "scanQrFromImage" -> {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath == null) {
          result.success(mapOf(
            "success" to false,
            "error" to "Image path is required"
          ))
          return
        }

        executor.execute {
          val qrResult = try {
            scanQrCode(imagePath)
          } catch (e: Exception) {
            mapOf("success" to false, "error" to "Error scanning QR code: ${e.message}")
          }
          android.os.Handler(android.os.Looper.getMainLooper()).post {
            result.success(qrResult)
          }
        }
      }
      "scanAllQrFromImage" -> {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath == null) {
          result.success(mapOf(
            "success" to false,
            "error" to "Image path is required"
          ))
          return
        }

        executor.execute {
          val qrResult = try {
            scanAllQrCodes(imagePath)
          } catch (e: Exception) {
            mapOf("success" to false, "error" to "Error scanning QR codes: ${e.message}")
          }
          android.os.Handler(android.os.Looper.getMainLooper()).post {
            result.success(qrResult)
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun scanQrCode(imagePath: String): Map<String, Any> {
    try {
      val file = File(imagePath)
      if (!file.exists()) {
        return mapOf(
          "success" to false,
          "error" to "Image file not found: $imagePath"
        )
      }

      var bitmap = BitmapFactory.decodeFile(imagePath)
      if (bitmap == null) {
        return mapOf(
          "success" to false,
          "error" to "Unable to decode image file"
        )
      }

      // Try multiple times with different image sizes like Aegis does
      for (i in 0..2) {
        if (i != 0) {
          // Resize bitmap for subsequent attempts
          val newWidth = bitmap.width / (i * 2)
          val newHeight = bitmap.height / (i * 2)
          if (newWidth > 0 && newHeight > 0) {
            bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
          }
        }

        try {
          val width = bitmap.width
          val height = bitmap.height
          val pixels = IntArray(width * height)
          bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

          val source = RGBLuminanceSource(width, height, pixels)
          val binaryBitmap = BinaryBitmap(HybridBinarizer(source))

          val reader = MultiFormatReader()
          val hints = HashMap<DecodeHintType, Any>()
          hints[DecodeHintType.POSSIBLE_FORMATS] = listOf(BarcodeFormat.QR_CODE)
          hints[DecodeHintType.TRY_HARDER] = true
          hints[DecodeHintType.ALSO_INVERTED] = true
          reader.setHints(hints)

          val qrResult: ZXingResult = reader.decode(binaryBitmap)
          
          return mapOf(
            "success" to true,
            "content" to qrResult.text
          )
        } catch (e: NotFoundException) {
          // Continue to next iteration
          continue
        }
      }

      return mapOf(
        "success" to false,
        "error" to "No QR code found in image"
      )
    } catch (e: Exception) {
      return mapOf(
        "success" to false,
        "error" to "Error scanning QR code: ${e.message}"
      )
    }
  }

  private fun scanAllQrCodes(imagePath: String): Map<String, Any> {
    val file = File(imagePath)
    if (!file.exists()) {
      return mapOf(
        "success" to false,
        "error" to "Image file not found: $imagePath"
      )
    }

    val origBitmap = BitmapFactory.decodeFile(imagePath)
      ?: return mapOf(
        "success" to false,
        "error" to "Unable to decode image file"
      )

    var bitmap = origBitmap
    try {
      val origWidth = origBitmap.width.toDouble()
      val origHeight = origBitmap.height.toDouble()

      for (i in 0..2) {
        if (i != 0) {
          val newWidth = origBitmap.width / (i * 2)
          val newHeight = origBitmap.height / (i * 2)
          if (newWidth > 0 && newHeight > 0) {
            if (bitmap !== origBitmap) bitmap.recycle()
            bitmap = Bitmap.createScaledBitmap(origBitmap, newWidth, newHeight, true)
          }
        }

        try {
          val width = bitmap.width
          val height = bitmap.height
          val pixels = IntArray(width * height)
          bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

          val source = RGBLuminanceSource(width, height, pixels)
          val binaryBitmap = BinaryBitmap(HybridBinarizer(source))

          val reader = MultiFormatReader()
          val hints = HashMap<DecodeHintType, Any>()
          hints[DecodeHintType.POSSIBLE_FORMATS] = listOf(BarcodeFormat.QR_CODE)
          hints[DecodeHintType.TRY_HARDER] = true
          hints[DecodeHintType.ALSO_INVERTED] = true
          reader.setHints(hints)

          val multiReader = GenericMultipleBarcodeReader(reader)
          val results: Array<ZXingResult> = multiReader.decodeMultiple(binaryBitmap, hints)

          val detections = mutableListOf<Map<String, Any>>()
          val scaleX = if (i == 0) 1.0 else (i * 2).toDouble()
          val scaleY = if (i == 0) 1.0 else (i * 2).toDouble()

          for (qrResult in results) {
            val points = qrResult.resultPoints
            if (points == null || points.isEmpty()) continue

            var minX = Float.MAX_VALUE
            var minY = Float.MAX_VALUE
            var maxX = -Float.MAX_VALUE
            var maxY = -Float.MAX_VALUE

            for (point in points) {
              if (point == null) continue
              val px = point.x * scaleX.toFloat()
              val py = point.y * scaleY.toFloat()
              if (px < minX) minX = px
              if (py < minY) minY = py
              if (px > maxX) maxX = px
              if (py > maxY) maxY = py
            }

            // Add padding around finder patterns (they mark corners, not edges)
            val padX = (maxX - minX) * 0.15f
            val padY = (maxY - minY) * 0.15f
            minX = (minX - padX).coerceAtLeast(0f)
            minY = (minY - padY).coerceAtLeast(0f)
            maxX = (maxX + padX).coerceAtMost(origWidth.toFloat())
            maxY = (maxY + padY).coerceAtMost(origHeight.toFloat())

            detections.add(mapOf(
              "content" to qrResult.text,
              "x" to (minX / origWidth),
              "y" to (minY / origHeight),
              "width" to ((maxX - minX) / origWidth),
              "height" to ((maxY - minY) / origHeight),
            ))
          }

          if (detections.isNotEmpty()) {
            if (bitmap !== origBitmap) bitmap.recycle()
            origBitmap.recycle()
            return mapOf(
              "success" to true,
              "detections" to detections
            )
          }
        } catch (e: NotFoundException) {
          continue
        }
      }

      if (bitmap !== origBitmap) bitmap.recycle()
      origBitmap.recycle()

      return mapOf(
        "success" to false,
        "error" to "No QR code found in image"
      )
    } catch (e: Exception) {
      if (bitmap !== origBitmap) bitmap.recycle()
      origBitmap.recycle()
      return mapOf(
        "success" to false,
        "error" to "Error scanning QR codes: ${e.message}"
      )
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
