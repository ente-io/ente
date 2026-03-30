package io.ente.auth.ente_qr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
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

  companion object {
    private const val SCAN_MAX_DIM = 1200
  }

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

  // ── Image loading & pre-processing ────────────────────────────────

  private fun loadAtMaxDimension(imagePath: String, maxDim: Int): Bitmap? {
    val opts = BitmapFactory.Options()
    opts.inJustDecodeBounds = true
    BitmapFactory.decodeFile(imagePath, opts)
    val w = opts.outWidth
    val h = opts.outHeight
    if (w <= 0 || h <= 0) return null

    var inSampleSize = 1
    if (w > maxDim || h > maxDim) {
      val halfW = w / 2
      val halfH = h / 2
      while (halfW / inSampleSize >= maxDim ||
             halfH / inSampleSize >= maxDim) {
        inSampleSize *= 2
      }
    }

    val decodeOpts = BitmapFactory.Options()
    decodeOpts.inSampleSize = inSampleSize
    return BitmapFactory.decodeFile(imagePath, decodeOpts)
  }

  private fun applyExifOrientation(bitmap: Bitmap, imagePath: String): Bitmap {
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

  private fun fixTransparency(bitmap: Bitmap): Bitmap {
    if (!bitmap.hasAlpha()) return bitmap
    val opaque = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(opaque)
    canvas.drawColor(Color.WHITE)
    canvas.drawBitmap(bitmap, 0f, 0f, null)
    bitmap.recycle()
    return opaque
  }

  private fun prepareBitmap(imagePath: String, maxDim: Int): Bitmap? {
    val raw = loadAtMaxDimension(imagePath, maxDim) ?: return null
    val oriented = applyExifOrientation(raw, imagePath)
    return fixTransparency(oriented)
  }

  // ── ZXing helpers ─────────────────────────────────────────────────

  private fun fastHints(): HashMap<DecodeHintType, Any> {
    val hints = HashMap<DecodeHintType, Any>()
    hints[DecodeHintType.POSSIBLE_FORMATS] = listOf(BarcodeFormat.QR_CODE)
    hints[DecodeHintType.ALSO_INVERTED] = true
    return hints
  }

  private fun thoroughHints(): HashMap<DecodeHintType, Any> {
    val hints = fastHints()
    hints[DecodeHintType.TRY_HARDER] = true
    return hints
  }

  private fun getPixels(bitmap: Bitmap): IntArray {
    val pixels = IntArray(bitmap.width * bitmap.height)
    bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
    return pixels
  }

  // ── ZXing decode ──────────────────────────────────────────────────

  private fun zxingDecode(pixels: IntArray, width: Int, height: Int, hints: HashMap<DecodeHintType, Any>): ZXingResult? {
    val reader = MultiFormatReader()
    reader.setHints(hints)

    try {
      val source = RGBLuminanceSource(width, height, pixels)
      return reader.decode(BinaryBitmap(HybridBinarizer(source)))
    } catch (_: NotFoundException) {}

    try {
      val source = RGBLuminanceSource(width, height, pixels)
      return reader.decode(BinaryBitmap(GlobalHistogramBinarizer(source)))
    } catch (_: NotFoundException) {}

    return null
  }

  private fun zxingDecodeMultiple(pixels: IntArray, width: Int, height: Int, hints: HashMap<DecodeHintType, Any>): Array<ZXingResult>? {
    val reader = MultiFormatReader()
    reader.setHints(hints)
    val multiReader = GenericMultipleBarcodeReader(reader)

    try {
      val source = RGBLuminanceSource(width, height, pixels)
      return multiReader.decodeMultiple(BinaryBitmap(HybridBinarizer(source)), hints)
    } catch (_: NotFoundException) {}

    try {
      val source = RGBLuminanceSource(width, height, pixels)
      return multiReader.decodeMultiple(BinaryBitmap(GlobalHistogramBinarizer(source)), hints)
    } catch (_: NotFoundException) {}

    return null
  }

  // ── Main scan methods ─────────────────────────────────────────────
  //
  // Two-phase strategy:
  //   Phase 1 (fast): No TRY_HARDER, single resolution, dual binarizer
  //            → resolves most photos in <200ms
  //   Phase 2 (thorough): Only if phase 1 found something — re-scan
  //            with TRY_HARDER to catch additional QR codes
  //
  // Images without QR codes (the common case) only pay the phase 1 cost.

  private fun scanQrCode(imagePath: String): Map<String, Any> {
    try {
      val file = File(imagePath)
      if (!file.exists()) {
        return mapOf("success" to false, "error" to "Image file not found: $imagePath")
      }

      val bitmap = prepareBitmap(imagePath, SCAN_MAX_DIM)
        ?: return mapOf("success" to false, "error" to "Unable to decode image file")

      try {
        val pixels = getPixels(bitmap)
        val w = bitmap.width
        val h = bitmap.height

        // Phase 1: fast scan (no TRY_HARDER)
        val fastResult = zxingDecode(pixels, w, h, fastHints())
        if (fastResult != null) {
          return mapOf("success" to true, "content" to fastResult.text)
        }

        // Phase 2: thorough scan (TRY_HARDER) only as fallback
        val thoroughResult = zxingDecode(pixels, w, h, thoroughHints())
        if (thoroughResult != null) {
          return mapOf("success" to true, "content" to thoroughResult.text)
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

    val bitmap = prepareBitmap(imagePath, SCAN_MAX_DIM)
      ?: return mapOf("success" to false, "error" to "Unable to decode image file")

    try {
      val pixels = getPixels(bitmap)
      val w = bitmap.width
      val h = bitmap.height
      val imgW = w.toDouble()
      val imgH = h.toDouble()

      // Phase 1: fast scan (no TRY_HARDER)
      val fastResults = zxingDecodeMultiple(pixels, w, h, fastHints())
      if (fastResults != null && fastResults.isNotEmpty()) {
        val detections = buildDetections(fastResults, imgW, imgH)
        if (detections.isNotEmpty()) {
          return mapOf("success" to true, "detections" to detections)
        }
      }

      // Phase 2: thorough scan (TRY_HARDER) only as fallback
      val thoroughResults = zxingDecodeMultiple(pixels, w, h, thoroughHints())
      if (thoroughResults != null && thoroughResults.isNotEmpty()) {
        val detections = buildDetections(thoroughResults, imgW, imgH)
        if (detections.isNotEmpty()) {
          return mapOf("success" to true, "detections" to detections)
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
        if (point.x < minX) minX = point.x
        if (point.y < minY) minY = point.y
        if (point.x > maxX) maxX = point.x
        if (point.y > maxY) maxY = point.y
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
