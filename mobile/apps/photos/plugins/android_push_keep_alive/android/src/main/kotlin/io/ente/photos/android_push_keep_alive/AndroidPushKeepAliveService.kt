package io.ente.photos.android_push_keep_alive

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

class AndroidPushKeepAliveService : Service() {

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    startForeground(PUSH_KEEP_ALIVE_NOTIFICATION_ID, buildNotification())
    return START_NOT_STICKY
  }

  override fun onDestroy() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      stopForeground(STOP_FOREGROUND_REMOVE)
    } else {
      @Suppress("DEPRECATION")
      stopForeground(true)
    }
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun buildNotification(): Notification {
    val channelId = notificationChannelId(this)
    ensureChannel(channelId)
    return NotificationCompat.Builder(this, channelId)
      .setSmallIcon(android.R.drawable.stat_notify_sync)
      .setContentTitle(getString(R.string.push_keep_alive_notification_title))
      .setContentText(getString(R.string.push_keep_alive_notification_body))
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setShowWhen(false)
      .setSilent(true)
      .setCategory(NotificationCompat.CATEGORY_SERVICE)
      .setPriority(NotificationCompat.PRIORITY_LOW)
      .build()
  }

  private fun ensureChannel(channelId: String) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      return
    }

    val notificationManager = getSystemService(NotificationManager::class.java)
    if (notificationManager.getNotificationChannel(channelId) != null) {
      return
    }

    val channel = NotificationChannel(
      channelId,
      getString(R.string.push_keep_alive_channel_name),
      NotificationManager.IMPORTANCE_LOW
    ).apply {
      description = getString(R.string.push_keep_alive_channel_description)
      setShowBadge(false)
      enableLights(false)
      enableVibration(false)
    }

    notificationManager.createNotificationChannel(channel)
  }

  companion object {
    const val CHANNEL_NAME = "android_push_keep_alive/background_keep_alive"
    const val METHOD_IS_ENABLED = "isPushKeepAliveEnabled"
    const val METHOD_START = "startPushKeepAlive"
    const val METHOD_STOP = "stopPushKeepAlive"

    private const val FLUTTER_SHARED_PREFERENCES_NAME = "FlutterSharedPreferences"
    private const val FLUTTER_KEY_PREFIX = "flutter."
    private const val REMOTE_FLAGS_KEY = "${FLUTTER_KEY_PREFIX}remote_flags"
    private const val INTERNAL_USER_DISABLED_KEY =
      "${FLUTTER_KEY_PREFIX}ls.internal_user_disabled"
    private const val PUSH_KEEP_ALIVE_NOTIFICATION_ID = 0x504b41

    fun isEnabled(context: Context): Boolean {
      val sharedPreferences = flutterSharedPreferences(context)
      val isDisabled = sharedPreferences.getBoolean(INTERNAL_USER_DISABLED_KEY, false)
      val isInternalUser = readInternalUser(sharedPreferences)
      return isInternalUser && !isDisabled
    }

    fun start(context: Context) {
      if (!isEnabled(context)) {
        return
      }

      val appContext = context.applicationContext
      val intent = Intent(appContext, AndroidPushKeepAliveService::class.java)

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        ContextCompat.startForegroundService(appContext, intent)
      } else {
        appContext.startService(intent)
      }
    }

    fun stop(context: Context) {
      val appContext = context.applicationContext
      val intent = Intent(appContext, AndroidPushKeepAliveService::class.java)
      appContext.stopService(intent)
    }

    private fun flutterSharedPreferences(context: Context): SharedPreferences {
      return context.getSharedPreferences(
        FLUTTER_SHARED_PREFERENCES_NAME,
        Context.MODE_PRIVATE,
      )
    }

    private fun readInternalUser(sharedPreferences: SharedPreferences): Boolean {
      val rawFlags = sharedPreferences.getString(REMOTE_FLAGS_KEY, null) ?: return false
      return try {
        JSONObject(rawFlags).optBoolean("internalUser", false)
      } catch (_: Exception) {
        false
      }
    }

    private fun notificationChannelId(context: Context): String {
      return "${context.packageName}.android_push_keep_alive"
    }
  }
}
