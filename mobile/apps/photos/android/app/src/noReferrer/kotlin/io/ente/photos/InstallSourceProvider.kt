package io.ente.photos

import android.content.Context
import io.flutter.plugin.common.MethodChannel

class InstallSourceProvider(context: Context) {
    private val store = InstallSourceEventStore(context)

    fun hasInstallSource(result: MethodChannel.Result) {
        result.success(false)
    }

    fun logInstallSource(result: MethodChannel.Result) {
        val source = store.sourceFromState() ?: store.fallbackSource()
        result.success(store.logInstallSource(source))
    }
}
