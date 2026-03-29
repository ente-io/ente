package io.ente.auth.ente_qr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import androidx.annotation.NonNull
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.android.gms.tasks.Tasks
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

  private val mlKitOptions = BarcodeScannerOptions.Builder()
    .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
    .build()

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

  // ── ZXing fast path (single pass at original resolution) ──────────

  /**
   * Quick ZXing decode at original resolution with HybridBinarizer.
   * Handles ~80% of clear QR codes instantly.
   */
  private fun zxingQuickDecode(bitmap: Bitmap): ZXingResult? {
    val width = bitmap.width
    val height = bitmap.height
    val pixels = IntArray(width * height)
    bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
    val source = RGBLuminanceSource(width, height, pixels)
    val reader = MultiFormatReader()
    reader.setHints(createDecodeHints())
    return try {
      reader.decode(BinaryBitmap(HybridBinarizer(source)))
    } catch (_: NotFoundException) {
      null
    }
  }

  /**
   * Quick ZXing multi-decode at original resolution.
   */
  private fun zxingQuickDecodeMultiple(bitmap: Bitmap): Array<ZXingResult>? {
    val width = bitmap.width
    val height = bitmap.height
    val pixels = IntArray(width * height)
    bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
    val source = RGBLuminanceSource(width, height, pixels)
    val hints = createDecodeHints()
    val reader = MultiFormatReader()
    reader.setHints(hints)
    val multiReader = GenericMultipleBarcodeReader(reader)
    return try {
      multiReader.decodeMultiple(BinaryBitmap(HybridBinarizer(source)), hints)
    } catch (_: NotFoundException) {
      null
    }
  }

  // ── ML Kit (handles all difficult cases) ──────────────────────────

  private fun mlKitScanSingle(bitmap: Bitmap): String? {
    val scanner = BarcodeScanning.getClient(mlKitOptions)
    return try {
      val inputImage = InputImage.fromBitmap(bitmap, 0)
      val barcodes = Tasks.await(scanner.process(inputImage))
      barcodes.firstOrNull { it.rawValue != null }?.rawValue
    } catch (_: Exception) {
      null
    } finally {
      scanner.close()
    }
  }

  private fun mlKitScanMultiple(bitmap: Bitmap): List<Map<String, Any>>? {
    val scanner = BarcodeScanning.getClient(mlKitOptions)
    return try {
      val inputImage = InputImage.fromBitmap(bitmap, 0)
      val barcodes = Tasks.await(scanner.process(inputImage))
      val imgWidth = bitmap.width.toDouble()
      val imgHeight = bitmap.height.toDouble()

      val detections = barcodes.mapNotNull { barcode ->
        val content = barcode.rawValue ?: return@mapNotNull null
        val box = barcode.boundingBox ?: return@mapNotNull null
        mapOf(
          "content" to content,
          "x" to (box.left / imgWidth),
          "y" to (box.top / imgHeight),
          "width" to (box.width() / imgWidth),
          "height" to (box.height() / imgHeight),
        )
      }
      detections.ifEmpty { null }
    } catch (_: Exception) {
      null
    } finally {
      scanner.close()
    }
  }

  // ── Main scan methods ─────────────────────────────────────────────
  //
  // Strategy: ZXing fast pass → ML Kit fallback
  // - ZXing at original resolution handles most clear QR codes instantly
  // - ML Kit handles everything else (moiré, distortion, low contrast,
  //   small QR codes, inverted colors) without wasting time on ZXing
  //   multi-resolution/multi-binarizer attempts

  private fun scanQrCode(imagePath: String): Map<String, Any> {
    try {
      val file = File(imagePath)
      if (!file.exists()) {
        return mapOf("success" to false, "error" to "Image file not found: $imagePath")
      }

      val bitmap = loadBitmapWithOrientation(imagePath)
        ?: return mapOf("success" to false, "error" to "Unable to decode image file")

      try {
        // Fast path: ZXing at original resolution
        val zxingResult = zxingQuickDecode(bitmap)
        if (zxingResult != null) {
          return mapOf("success" to true, "content" to zxingResult.text)
        }

        // ML Kit fallback
        val mlResult = mlKitScanSingle(bitmap)
        if (mlResult != null) {
          return mapOf("success" to true, "content" to mlResult)
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

      // Fast path: ZXing at original resolution
      val zxingResults = zxingQuickDecodeMultiple(bitmap)
      if (zxingResults != null && zxingResults.isNotEmpty()) {
        val detections = mutableListOf<Map<String, Any>>()

        for (qrResult in zxingResults) {
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

        if (detections.isNotEmpty()) {
          return mapOf("success" to true, "detections" to detections)
        }
      }

      // ML Kit fallback
      val mlDetections = mlKitScanMultiple(bitmap)
      if (mlDetections != null) {
        return mapOf("success" to true, "detections" to mlDetections)
      }

      return mapOf("success" to false, "error" to "No QR code found in image")
    } catch (e: Exception) {
      return mapOf("success" to false, "error" to "Error scanning QR codes: ${e.message}")
    } finally {
      bitmap.recycle()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
