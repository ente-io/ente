package io.ente.auth.ente_qr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import androidx.annotation.NonNull
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader
import com.google.zxing.NotFoundException
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.Result as ZXingResult
import com.google.zxing.common.GlobalHistogramBinarizer
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

  /**
   * Load a bitmap and apply EXIF orientation so the image is upright
   * before QR detection.
   */
  private fun loadBitmapWithOrientation(imagePath: String): Bitmap? {
    val bitmap = BitmapFactory.decodeFile(imagePath) ?: return null
    return try {
      val exif = ExifInterface(imagePath)
      val orientation = exif.getAttributeInt(
        ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
      )
      val matrix = Matrix()
      when (orientation) {
        ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
        ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
        ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
        ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
        else -> return bitmap
      }
      val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
      if (rotated !== bitmap) bitmap.recycle()
      rotated
    } catch (_: Exception) {
      bitmap
    }
  }

  private fun createDecodeHints(): HashMap<DecodeHintType, Any> {
    val hints = HashMap<DecodeHintType, Any>()
    hints[DecodeHintType.POSSIBLE_FORMATS] = listOf(BarcodeFormat.QR_CODE)
    hints[DecodeHintType.TRY_HARDER] = true
    hints[DecodeHintType.ALSO_INVERTED] = true
    return hints
  }

  private fun getPixels(bitmap: Bitmap): IntArray {
    val width = bitmap.width
    val height = bitmap.height
    val pixels = IntArray(width * height)
    bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
    return pixels
  }

  // ── ZXing decode strategies ───────────────────────────────────────
  //
  // 1. HybridBinarizer at original resolution (fast, handles most cases)
  // 2. GlobalHistogramBinarizer at original resolution (uneven lighting)
  // 3. HybridBinarizer at half resolution (moiré, noise)

  private fun zxingDecode(pixels: IntArray, width: Int, height: Int, hints: HashMap<DecodeHintType, Any>): ZXingResult? {
    val source = RGBLuminanceSource(width, height, pixels)
    val reader = MultiFormatReader()
    reader.setHints(hints)

    // Strategy 1: HybridBinarizer
    try {
      return reader.decode(BinaryBitmap(HybridBinarizer(source)))
    } catch (_: NotFoundException) {}

    // Strategy 2: GlobalHistogramBinarizer
    try {
      val source2 = RGBLuminanceSource(width, height, pixels)
      return reader.decode(BinaryBitmap(GlobalHistogramBinarizer(source2)))
    } catch (_: NotFoundException) {}

    return null
  }

  private fun zxingDecodeMultiple(pixels: IntArray, width: Int, height: Int, hints: HashMap<DecodeHintType, Any>): Array<ZXingResult>? {
    val source = RGBLuminanceSource(width, height, pixels)
    val reader = MultiFormatReader()
    reader.setHints(hints)
    val multiReader = GenericMultipleBarcodeReader(reader)

    // Strategy 1: HybridBinarizer
    try {
      return multiReader.decodeMultiple(BinaryBitmap(HybridBinarizer(source)), hints)
    } catch (_: NotFoundException) {}

    // Strategy 2: GlobalHistogramBinarizer
    try {
      val source2 = RGBLuminanceSource(width, height, pixels)
      return multiReader.decodeMultiple(BinaryBitmap(GlobalHistogramBinarizer(source2)), hints)
    } catch (_: NotFoundException) {}

    return null
  }

  // ── Main scan methods ─────────────────────────────────────────────

  private fun scanQrCode(imagePath: String): Map<String, Any> {
    try {
      val file = File(imagePath)
      if (!file.exists()) {
        return mapOf("success" to false, "error" to "Image file not found: $imagePath")
      }

      val bitmap = loadBitmapWithOrientation(imagePath)
        ?: return mapOf("success" to false, "error" to "Unable to decode image file")

      try {
        val hints = createDecodeHints()

        // Try at original resolution
        val pixels = getPixels(bitmap)
        val result = zxingDecode(pixels, bitmap.width, bitmap.height, hints)
        if (result != null) {
          return mapOf("success" to true, "content" to result.text)
        }

        // Fallback: half resolution (helps with moiré/noise)
        val halfW = bitmap.width / 2
        val halfH = bitmap.height / 2
        if (halfW > 0 && halfH > 0) {
          val halfBitmap = Bitmap.createScaledBitmap(bitmap, halfW, halfH, true)
          try {
            val halfPixels = getPixels(halfBitmap)
            val halfResult = zxingDecode(halfPixels, halfW, halfH, hints)
            if (halfResult != null) {
              return mapOf("success" to true, "content" to halfResult.text)
            }
          } finally {
            halfBitmap.recycle()
          }
        }

        return mapOf("success" to false, "error" to "No QR code found in image")
      } finally {
        bitmap.recycle()
      }
    } catch (e: Exception) {
      return mapOf("success" to false, "error" to "Error scanning QR code: ${e.message}")
    }
  }

  private fun scanAllQrCodes(imagePath: String): Map<String, Any> {
    val file = File(imagePath)
    if (!file.exists()) {
      return mapOf("success" to false, "error" to "Image file not found: $imagePath")
    }

    val bitmap = loadBitmapWithOrientation(imagePath)
      ?: return mapOf("success" to false, "error" to "Unable to decode image file")

    try {
      val imgWidth = bitmap.width.toDouble()
      val imgHeight = bitmap.height.toDouble()
      val hints = createDecodeHints()

      // Try at original resolution
      val pixels = getPixels(bitmap)
      val results = zxingDecodeMultiple(pixels, bitmap.width, bitmap.height, hints)
      if (results != null && results.isNotEmpty()) {
        val detections = buildDetections(results, imgWidth, imgHeight, 1.0)
        if (detections.isNotEmpty()) {
          return mapOf("success" to true, "detections" to detections)
        }
      }

      // Fallback: half resolution
      val halfW = bitmap.width / 2
      val halfH = bitmap.height / 2
      if (halfW > 0 && halfH > 0) {
        val halfBitmap = Bitmap.createScaledBitmap(bitmap, halfW, halfH, true)
        try {
          val halfPixels = getPixels(halfBitmap)
          val halfResults = zxingDecodeMultiple(halfPixels, halfW, halfH, hints)
          if (halfResults != null && halfResults.isNotEmpty()) {
            val detections = buildDetections(halfResults, imgWidth, imgHeight, 2.0)
            if (detections.isNotEmpty()) {
              return mapOf("success" to true, "detections" to detections)
            }
          }
        } finally {
          halfBitmap.recycle()
        }
      }

      return mapOf("success" to false, "error" to "No QR code found in image")
    } catch (e: Exception) {
      return mapOf("success" to false, "error" to "Error scanning QR codes: ${e.message}")
    } finally {
      bitmap.recycle()
    }
  }

  private fun buildDetections(
    results: Array<ZXingResult>,
    imgWidth: Double,
    imgHeight: Double,
    scale: Double,
  ): List<Map<String, Any>> {
    val detections = mutableListOf<Map<String, Any>>()

    for (qrResult in results) {
      val points = qrResult.resultPoints
      if (points == null || points.isEmpty()) continue

      var minX = Float.MAX_VALUE
      var minY = Float.MAX_VALUE
      var maxX = -Float.MAX_VALUE
      var maxY = -Float.MAX_VALUE

      for (point in points) {
        if (point == null) continue
        val px = (point.x * scale).toFloat()
        val py = (point.y * scale).toFloat()
        if (px < minX) minX = px
        if (py < minY) minY = py
        if (px > maxX) maxX = px
        if (py > maxY) maxY = py
      }

      // Add padding around finder patterns
      val padX = (maxX - minX) * 0.15f
      val padY = (maxY - minY) * 0.15f
      minX = (minX - padX).coerceAtLeast(0f)
      minY = (minY - padY).coerceAtLeast(0f)
      maxX = (maxX + padX).coerceAtMost(imgWidth.toFloat())
      maxY = (maxY + padY).coerceAtMost(imgHeight.toFloat())

      detections.add(mapOf(
        "content" to qrResult.text,
        "x" to (minX / imgWidth),
        "y" to (minY / imgHeight),
        "width" to ((maxX - minX) / imgWidth),
        "height" to ((maxY - minY) / imgHeight),
      ))
    }

    return detections
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
