package com.example.flutterimagecompress.exif

import androidx.exifinterface.media.ExifInterface
import java.io.ByteArrayInputStream
import java.io.File


object Exif {
  fun getRotationDegrees(_bytes: ByteArray): Int {
    return try {
      getFromExifInterface(_bytes)
    } catch (e: Exception) {
      0
    }
  }
  
  private fun getFromExifInterface(byteArray: ByteArray): Int {
    val exifInterface = ExifInterface(ByteArrayInputStream(byteArray))
    return exifInterface.rotationDegrees
  }
  
  fun getRotationDegrees(file: File): Int {
    return try {
      ExifInterface(file.absolutePath).rotationDegrees
    } catch (e: Exception) {
      0
    }
  }
  
}