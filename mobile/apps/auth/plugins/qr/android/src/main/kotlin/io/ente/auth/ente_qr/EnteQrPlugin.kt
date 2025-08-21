package io.ente.auth.ente_qr

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
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.*

/** EnteQrPlugin */
class EnteQrPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

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
        
        try {
          val qrResult = scanQrCode(imagePath)
          result.success(qrResult)
        } catch (e: Exception) {
          result.success(mapOf(
            "success" to false,
            "error" to "Error scanning QR code: ${e.message}"
          ))
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

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
