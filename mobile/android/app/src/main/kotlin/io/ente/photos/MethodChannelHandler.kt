package io.ente.photos

import android.content.SharedPreferences
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MethodChannelHandler : MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var activity: MainActivity

    fun onAttachedToEngine(binaryMessenger: BinaryMessenger) {
        channel = MethodChannel(binaryMessenger, "ente_login_channel")
        channel.setMethodCallHandler(this)
    }

    fun onDetachedFromEngine() {
        channel.setMethodCallHandler(null)
    }

    fun setActivity(activity: MainActivity) {
        this.activity = activity
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "saveUsername" -> {
                val username = call.argument<String>("username")
                val sharedPrefs = activity.getSharedPreferences("ente_prefs", android.content.Context.MODE_PRIVATE)
                sharedPrefs.edit().putString("username", username).apply()
                Log.d("UpEnte", "[DEBUG] Saved username to native SharedPreferences: $username")
                val current = sharedPrefs.getString("username", null)
                Log.d("UpEnte", "[DEBUG] Username in native SharedPreferences after save: $current")
                result.success(true)
            }
            "clearUsername" -> {
                val sharedPrefs = activity.getSharedPreferences("ente_prefs", android.content.Context.MODE_PRIVATE)
                sharedPrefs.edit().remove("username").apply()
                Log.d("UpEnte", "[DEBUG] Cleared username from native SharedPreferences")
                result.success(true)
            }
            "logout" -> {
                Log.d("UpEnte", "Received logout request from Flutter")
                activity.handleLogoutFromFlutter()
                result.success(true)
            }
            "getCurrentUsername" -> {
                val username = getCurrentUsernameFromNativePreferences()
                Log.d("UpEnte", "Retrieved current username from native SharedPreferences: $username")
                result.success(username)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun saveUsernameToNativePreferences(username: String) {
        Log.d("UpEnte", "[DEBUG] About to save username to native SharedPreferences: $username")
        val sharedPrefs: SharedPreferences = activity.getSharedPreferences("ente_prefs", android.content.Context.MODE_PRIVATE)
        val editor = sharedPrefs.edit()
        editor.putString("username", username)
        editor.apply()
        Log.d("UpEnte", "[DEBUG] Saved username to native SharedPreferences: $username")
    }

    private fun clearUsernameFromNativePreferences() {
        Log.d("UpEnte", "[DEBUG] About to clear username from native SharedPreferences")
        val sharedPrefs: SharedPreferences = activity.getSharedPreferences("ente_prefs", android.content.Context.MODE_PRIVATE)
        val editor = sharedPrefs.edit()
        editor.remove("username")
        editor.apply()
        Log.d("UpEnte", "[DEBUG] Cleared username from native SharedPreferences")
    }

    private fun getCurrentUsernameFromNativePreferences(): String? {
        Log.d("UpEnte", "[DEBUG] About to get current username from native SharedPreferences")
        val sharedPrefs: SharedPreferences = activity.getSharedPreferences("ente_prefs", android.content.Context.MODE_PRIVATE)
        val username = sharedPrefs.getString("username", null)
        Log.d("UpEnte", "[DEBUG] Retrieved current username from native SharedPreferences: $username")
        return username
    }
} 