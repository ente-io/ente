package com.example.flutterimagecompress

import android.content.Context
import android.os.Build
import com.example.flutterimagecompress.core.CompressFileHandler
import com.example.flutterimagecompress.core.CompressListHandler
import com.example.flutterimagecompress.format.FormatRegister
import com.example.flutterimagecompress.handle.common.CommonHandler
import com.example.flutterimagecompress.handle.heif.HeifHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterImageCompressPlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var context: Context
  var channel: MethodChannel? = null

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val plugin = FlutterImageCompressPlugin()
      plugin.channel = MethodChannel(registrar.messenger(), "flutter_image_compress")
      plugin.context = registrar.context()
      plugin.channel?.setMethodCallHandler(plugin)
    }

    var showLog = false
  }

  init {
    FormatRegister.registerFormat(CommonHandler(0)) // jpeg
    FormatRegister.registerFormat(CommonHandler(1)) // png
    FormatRegister.registerFormat(HeifHandler()) // heic / heif
    FormatRegister.registerFormat(CommonHandler(3)) // webp
  }

  override fun onMethodCall(call: MethodCall, result: Result): Unit {
    when (call.method) {
      "showLog" -> result.success(handleLog(call))
      "compressWithList" -> CompressListHandler(call, result).handle(context)
      "compressWithFile" -> CompressFileHandler(call, result).handle(context)
      "compressWithFileAndGetFile" -> CompressFileHandler(call, result).handleGetFile(context)
      "getSystemVersion" -> result.success(Build.VERSION.SDK_INT)
      else -> result.notImplemented()
    }
  }

  private fun handleLog(call: MethodCall): Int {
    val arg = call.arguments<Boolean>()
    showLog = (arg == true)
    return 1
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    this.context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "flutter_image_compress")
    channel?.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
  }

}
