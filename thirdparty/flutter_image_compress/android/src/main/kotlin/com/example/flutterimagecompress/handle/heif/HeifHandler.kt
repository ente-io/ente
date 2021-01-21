package com.example.flutterimagecompress.handle.heif

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.heifwriter.HeifWriter
import com.example.flutterimagecompress.ext.calcScale
import com.example.flutterimagecompress.ext.rotate
import com.example.flutterimagecompress.handle.FormatHandler
import com.example.flutterimagecompress.logger.log
import com.example.flutterimagecompress.util.TmpFileUtil
import java.io.OutputStream

class HeifHandler : FormatHandler {

  override val type: Int
    get() = 2

  override val typeName: String
    get() = "heif"

  override fun handleByteArray(context: Context, byteArray: ByteArray, outputStream: OutputStream, minWidth: Int, minHeight: Int, quality: Int, rotate: Int, keepExif: Boolean, inSampleSize: Int) {
    val tmpFile = TmpFileUtil.createTmpFile(context)
    compress(byteArray, minWidth, minHeight, quality, rotate, inSampleSize, tmpFile.absolutePath)
    outputStream.write(tmpFile.readBytes())
  }

  private fun compress(arr: ByteArray, minWidth: Int, minHeight: Int, quality: Int, rotate: Int = 0, inSampleSize: Int, targetPath: String) {
    val options = makeOption(inSampleSize)
    val bitmap = BitmapFactory.decodeByteArray(arr, 0, arr.count(), options)
    convertToHeif(bitmap, minWidth, minHeight, rotate, targetPath, quality)
  }

  private fun compress(path: String, minWidth: Int, minHeight: Int, quality: Int, rotate: Int = 0, inSampleSize: Int, targetPath: String) {
    val options = makeOption(inSampleSize)
    val bitmap = BitmapFactory.decodeFile(path, options)
    convertToHeif(bitmap, minWidth, minHeight, rotate, targetPath, quality)
  }

  private fun makeOption(inSampleSize: Int): BitmapFactory.Options {
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = false
    options.inPreferredConfig = Bitmap.Config.RGB_565
    options.inSampleSize = inSampleSize
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      @Suppress("DEPRECATION")
      options.inDither = true
    }
    return options
  }

  private fun convertToHeif(bitmap: Bitmap, minWidth: Int, minHeight: Int, rotate: Int, targetPath: String, quality: Int) {
    val w = bitmap.width.toFloat()
    val h = bitmap.height.toFloat()

    log("src width = $w")
    log("src height = $h")

    val scale = bitmap.calcScale(minWidth, minHeight)

    log("scale = $scale")

    val destW = w / scale
    val destH = h / scale

    log("dst width = $destW")
    log("dst height = $destH")

    val result = Bitmap.createScaledBitmap(bitmap, destW.toInt(), destH.toInt(), true)
            .rotate(rotate)

    val heifWriter = HeifWriter.Builder(targetPath, result.width, result.height, HeifWriter.INPUT_MODE_BITMAP)
            .setQuality(quality)
            .setMaxImages(1)
            .build()

    heifWriter.start()
    heifWriter.addBitmap(result)
    heifWriter.stop(5000)

    heifWriter.close()
  }

  override fun handleFile(context: Context, path: String, outputStream: OutputStream, minWidth: Int, minHeight: Int, quality: Int, rotate: Int, keepExif: Boolean, inSampleSize: Int) {
    val tmpFile = TmpFileUtil.createTmpFile(context)
    compress(path, minWidth, minHeight, quality, rotate, inSampleSize, tmpFile.absolutePath)
    outputStream.write(tmpFile.readBytes())
  }
}