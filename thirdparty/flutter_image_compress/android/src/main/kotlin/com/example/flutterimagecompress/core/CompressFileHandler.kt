package com.example.flutterimagecompress.core

import android.content.Context
import com.example.flutterimagecompress.FlutterImageCompressPlugin
import com.example.flutterimagecompress.exif.Exif
import com.example.flutterimagecompress.format.FormatRegister
import com.example.flutterimagecompress.logger.log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.OutputStream

class CompressFileHandler(private val call: MethodCall, result: MethodChannel.Result) : ResultHandler(result) {

  fun handle(context: Context) {
    threadPool.execute {
      @Suppress("UNCHECKED_CAST") val args: List<Any> = call.arguments as List<Any>
      val filePath = args[0] as String
      var minWidth = args[1] as Int
      var minHeight = args[2] as Int
      val quality = args[3] as Int
      val rotate = args[4] as Int
      val autoCorrectionAngle = args[5] as Boolean
      val format = args[6] as Int
      val keepExif = args[7] as Boolean
      val inSampleSize = args[8] as Int

      val formatHandler = FormatRegister.findFormat(format)

      if (formatHandler == null) {
        log("No support format.")
        reply(null)
        return@execute
      }

      val exifRotate =
              if (autoCorrectionAngle) {
                val bytes = File(filePath).readBytes()
                Exif.getRotationDegrees(bytes)
              } else {
                0
              }

      if (exifRotate == 270 || exifRotate == 90) {
        val tmp = minWidth
        minWidth = minHeight
        minHeight = tmp
      }
      val targetRotate = rotate + exifRotate
      val outputStream = ByteArrayOutputStream()
      try {
        formatHandler.handleFile(context, filePath, outputStream, minWidth, minHeight, quality, targetRotate, keepExif, inSampleSize)
        reply(outputStream.toByteArray())
      } catch (e: Exception) {
        if (FlutterImageCompressPlugin.showLog) e.printStackTrace()
        reply(null)
      } finally {
        outputStream.close()
      }
    }
  }

  fun handleGetFile(context: Context) {
    threadPool.execute {
      @Suppress("UNCHECKED_CAST") val args: List<Any> = call.arguments as List<Any>
      val file = args[0] as String
      var minWidth = args[1] as Int
      var minHeight = args[2] as Int
      val quality = args[3] as Int
      val targetPath = args[4] as String
      val rotate = args[5] as Int
      val autoCorrectionAngle = args[6] as Boolean

      val exifRotate =
              if (autoCorrectionAngle) {
                val bytes = File(file).readBytes()
                Exif.getRotationDegrees(bytes)
              } else {
                0
              }


      val format = args[7] as Int
      val keepExif = args[8] as Boolean
      val inSampleSize = args[9] as Int

      val formatHandler = FormatRegister.findFormat(format)

      if (formatHandler == null) {
        log("No support format.")
        reply(null)
        return@execute
      }

      if (exifRotate == 270 || exifRotate == 90) {
        val tmp = minWidth
        minWidth = minHeight
        minHeight = tmp
      }

      val targetRotate = rotate + exifRotate
      var outputStream: OutputStream? = null
      try {
        outputStream = File(targetPath).outputStream()
        formatHandler.handleFile(context, file, outputStream, minWidth, minHeight, quality, targetRotate, keepExif, inSampleSize)
        reply(targetPath)
      } catch (e: Exception) {
        if (FlutterImageCompressPlugin.showLog) e.printStackTrace()
        reply(null)
      } finally {
        outputStream?.close()
      }
    }
  }

}