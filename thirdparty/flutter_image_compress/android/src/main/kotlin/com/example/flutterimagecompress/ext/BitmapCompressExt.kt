package com.example.flutterimagecompress.ext

import android.graphics.Bitmap
import android.graphics.Matrix
import com.example.flutterimagecompress.FlutterImageCompressPlugin
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import kotlin.math.max
import kotlin.math.min

fun Bitmap.compress(minWidth: Int, minHeight: Int, quality: Int, rotate: Int = 0, format: Int): ByteArray {
  val outputStream = ByteArrayOutputStream()
  compress(minWidth, minHeight, quality, rotate, outputStream, format)
  return outputStream.toByteArray()
}

fun Bitmap.compress(minWidth: Int, minHeight: Int, quality: Int, rotate: Int = 0, outputStream: OutputStream, format: Int = 0) {
  val w = this.width.toFloat()
  val h = this.height.toFloat()
  
  log("src width = $w")
  log("src height = $h")
  
  val scale = calcScale(minWidth, minHeight)
  
  log("scale = $scale")
  
  val destW = w / scale
  val destH = h / scale
  
  log("dst width = $destW")
  log("dst height = $destH")
  
  Bitmap.createScaledBitmap(this, destW.toInt(), destH.toInt(), true)
    .rotate(rotate)
    .compress(convertFormatIndexToFormat(format), quality, outputStream)
}

private fun log(any: Any?) {
  if (FlutterImageCompressPlugin.showLog) {
    println(any ?: "null")
  }
}

fun Bitmap.rotate(rotate: Int): Bitmap {
  return if (rotate % 360 != 0) {
    val matrix = Matrix()
    matrix.setRotate(rotate.toFloat())
    // 围绕原地进行旋转
    Bitmap.createBitmap(this, 0, 0, width, height, matrix, false)
  } else {
    this
  }
}

fun Bitmap.calcScale(minWidth: Int, minHeight: Int): Float {
  val w = width.toFloat()
  val h = height.toFloat()
  
  val scaleW = w / minWidth.toFloat()
  val scaleH = h / minHeight.toFloat()
  
  log("width scale = $scaleW")
  log("height scale = $scaleH")
  
  return max(1f, min(scaleW, scaleH))
}

fun convertFormatIndexToFormat(type: Int): Bitmap.CompressFormat {
  return if (type == 1) Bitmap.CompressFormat.PNG else if (type == 3) Bitmap.CompressFormat.WEBP else Bitmap.CompressFormat.JPEG 
}
