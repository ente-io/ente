package io.ente.photos

import android.app.Application
import android.content.Context
import android.util.Log
import dev.fluttercommunity.workmanager.NotificationDebugHandler
import dev.fluttercommunity.workmanager.TaskDebugInfo
import dev.fluttercommunity.workmanager.TaskResult
import dev.fluttercommunity.workmanager.WorkmanagerDebug
import dev.fluttercommunity.workmanager.pigeon.TaskStatus
import org.json.JSONObject

class EnteApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    WorkmanagerDebug.setCurrent(InternalUserWorkmanagerDebugHandler())
  }

  companion object {
    const val FLUTTER_SHARED_PREFERENCES = "FlutterSharedPreferences"
    const val REMOTE_FLAGS_KEY = "flutter.remote_flags"
    const val INTERNAL_USER_DISABLED_KEY = "flutter.ls.internal_user_disabled"
    const val TAG = "EnteApplication"
  }
}

private class InternalUserWorkmanagerDebugHandler : WorkmanagerDebug() {
  private val delegate = NotificationDebugHandler()

  override fun onTaskStatusUpdate(
    context: Context,
    taskInfo: TaskDebugInfo,
    status: TaskStatus,
    result: TaskResult?,
  ) {
    if (!shouldEnableWorkmanagerDebugNotifications(context)) {
      return
    }
    delegate.onTaskStatusUpdate(context, taskInfo, status, result)
  }

  override fun onExceptionEncountered(
    context: Context,
    taskInfo: TaskDebugInfo?,
    exception: Throwable,
  ) {
    if (!shouldEnableWorkmanagerDebugNotifications(context)) {
      return
    }
    delegate.onExceptionEncountered(context, taskInfo, exception)
  }

  private fun shouldEnableWorkmanagerDebugNotifications(context: Context): Boolean {
    val prefs =
      context.getSharedPreferences(
        EnteApplication.FLUTTER_SHARED_PREFERENCES,
        Context.MODE_PRIVATE,
      )
    if (prefs.getBoolean(EnteApplication.INTERNAL_USER_DISABLED_KEY, false)) {
      return false
    }

    return BuildConfig.DEBUG || isInternalUser(prefs.getString(EnteApplication.REMOTE_FLAGS_KEY, null))
  }

  private fun isInternalUser(remoteFlags: String?): Boolean {
    if (remoteFlags.isNullOrBlank()) {
      return false
    }

    return runCatching {
      JSONObject(remoteFlags).optBoolean("internalUser", false)
    }.getOrElse {
      Log.w(
        EnteApplication.TAG,
        "Failed to parse remote flags for Workmanager debug handler",
        it,
      )
      false
    }
  }
}
