package io.ente.photos.screensaver.power

import android.app.Activity
import android.content.Context
import android.os.PowerManager

class ScreenWakeLockManager(context: Context) {

    // Guardrail: this wake lock is for foreground preview Activities only,
    // never for the DreamService screensaver runtime.
    private val enabled = context is Activity
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

    @Suppress("DEPRECATION")
    private val wakeLock: PowerManager.WakeLock by lazy {
        powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK,
            "${context.packageName}:ForegroundPreview",
        ).apply {
            setReferenceCounted(false)
        }
    }

    fun acquire() {
        if (!enabled) return
        if (!wakeLock.isHeld) {
            wakeLock.acquire()
        }
    }

    fun release() {
        if (!enabled) return
        if (wakeLock.isHeld) {
            wakeLock.release()
        }
    }
}
