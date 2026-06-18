package io.ente.photos

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object NativeChannels {
    fun register(context: Context, flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        InstallSourceChannel(context.applicationContext).register(messenger)
    }
}

private class InstallSourceChannel(context: Context) {
    private val provider = InstallSourceProvider(context)

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasInstallSource" -> provider.hasInstallSource(result)
            "autoAttributeSource" -> provider.autoAttributeSource(
                call.argument<Boolean>("isSignUp") == true,
                result,
            )
            "getPendingEvents" -> provider.getPendingEvents(result)
            "markEventSent" -> provider.markEventSent(call.argument("event"), result)
            else -> result.notImplemented()
        }
    }

    private companion object {
        const val CHANNEL = "io.ente.photos/install_source"
    }
}
