package io.ente.photos_tv

import android.service.dreams.DreamService
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class PhotosTvDreamService : DreamService() {
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        isInteractive = true
        isFullscreen = true
        val engine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(engine)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        val view = FlutterView(this)
        view.attachToFlutterEngine(engine)
        flutterEngine = engine
        flutterView = view
        setContentView(view)
    }

    override fun onDetachedFromWindow() {
        flutterView?.detachFromFlutterEngine()
        flutterView = null
        flutterEngine?.destroy()
        flutterEngine = null
        super.onDetachedFromWindow()
    }
}
