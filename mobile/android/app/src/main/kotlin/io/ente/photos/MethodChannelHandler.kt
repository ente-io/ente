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
                if (username != null && username.isNotEmpty()) {
                    saveUsernameToNativePreferences(username)
                    Log.d("UpEnte", "Received username from Flutter and saved to native SharedPreferences: $username")
                    result.success(true)
                } else {
                    Log.w("UpEnte", "Received null or empty username from Flutter")
                    result.error("INVALID_USERNAME", "Username is null or empty", null)
                }
            }
            "clearUsername" -> {
                clearUsernameFromNativePreferences()
                Log.d("UpEnte", "Cleared username from native SharedPreferences on logout")
                result.success(true)
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
} 