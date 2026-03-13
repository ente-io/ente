package io.ente.photos.android_push_keep_alive

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AndroidPushKeepAlivePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = binding.applicationContext
    channel = MethodChannel(
      binding.binaryMessenger,
      AndroidPushKeepAliveService.CHANNEL_NAME,
    )
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      AndroidPushKeepAliveService.METHOD_IS_ENABLED -> {
        result.success(AndroidPushKeepAliveService.isEnabled(applicationContext))
      }

      AndroidPushKeepAliveService.METHOD_START -> {
        AndroidPushKeepAliveService.start(applicationContext)
        result.success(null)
      }

      AndroidPushKeepAliveService.METHOD_STOP -> {
        AndroidPushKeepAliveService.stop(applicationContext)
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
