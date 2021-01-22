package com.example.flutterimagecompress.logger

import android.util.Log
import com.example.flutterimagecompress.FlutterImageCompressPlugin

fun Any.log(any: Any?) {
  if (FlutterImageCompressPlugin.showLog) {
    Log.i("flutter_image_compress", any?.toString() ?: "null")
  }
}