package io.ente.photos

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val installSourceProvider by lazy { InstallSourceProvider(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.ente.photos/install_source"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasInstallSource" -> installSourceProvider.hasInstallSource(result)
                "logInstallSource" -> installSourceProvider.logInstallSource(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}
