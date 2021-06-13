package top.kikt.imagescannerexample

import android.os.Bundle

import io.flutter.embedding.android.FlutterActivity

class MainActivity() : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CrashHandler.initHandler(this)
    }
}
