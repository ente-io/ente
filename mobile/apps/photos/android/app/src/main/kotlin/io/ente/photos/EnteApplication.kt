package io.ente.photos

import dev.fluttercommunity.workmanager.NotificationDebugHandler
import dev.fluttercommunity.workmanager.WorkmanagerDebug
import io.flutter.app.FlutterApplication

class EnteApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

        WorkmanagerDebug.setCurrent(NotificationDebugHandler())
    }
}
