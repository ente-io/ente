package io.ente.photos

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MethodChannelHandler {
    private lateinit var loginChannel: MethodChannel
    private lateinit var supportChannel: MethodChannel
    private lateinit var context: Context

    fun onAttachedToEngine(binaryMessenger: BinaryMessenger, context: Context) {
        this.context = context
        
        // Login channel handler
        loginChannel = MethodChannel(binaryMessenger, "ente_login_channel")
        loginChannel.setMethodCallHandler(LoginMethodCallHandler())
        
        // Support channel handler
        supportChannel = MethodChannel(binaryMessenger, "support_channel")
        supportChannel.setMethodCallHandler(SupportMethodCallHandler())
    }

    fun onDetachedFromEngine() {
        loginChannel.setMethodCallHandler(null)
        supportChannel.setMethodCallHandler(null)
    }

    // Login channel handler
    private inner class LoginMethodCallHandler : MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: Result) {
            when (call.method) {
                "saveUsername" -> {
                    val username = call.argument<String>("username")
                    val sharedPrefs = context.getSharedPreferences("ente_prefs", Context.MODE_PRIVATE)
                    sharedPrefs.edit().putString("username", username).apply()
                    Log.d("UpEnte", "[DEBUG] Saved username to native SharedPreferences: $username")
                    val current = sharedPrefs.getString("username", null)
                    Log.d("UpEnte", "[DEBUG] Username in native SharedPreferences after save: $current")
                    result.success(true)
                }
                "clearUsername" -> {
                    val sharedPrefs = context.getSharedPreferences("ente_prefs", Context.MODE_PRIVATE)
                    sharedPrefs.edit().remove("username").apply()
                    Log.d("UpEnte", "[DEBUG] Cleared username from native SharedPreferences")
                    result.success(true)
                }
                "logout" -> {
                    Log.d("UpEnte", "Received logout request from Flutter")
                    handleLogoutFromFlutter()
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
    }

    // Support channel handler
    private inner class SupportMethodCallHandler : MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: Result) {
            when (call.method) {
                "openSupportApp" -> {
                    try {
                        Log.d("UpEnte", "Opening support app")
                        val supportIntent = context.packageManager.getLaunchIntentForPackage("com.unplugged.support")
                        if (supportIntent != null) {
                            supportIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(supportIntent)
                            result.success(true)
                        } else {
                            Log.e("UpEnte", "Support app not found on device")
                            result.error("SUPPORT_APP_NOT_FOUND", "Support app not installed", null)
                        }
                    } catch (e: Exception) {
                        Log.e("UpEnte", "Failed to open support app", e)
                        result.error("SUPPORT_APP_ERROR", "Failed to open support app", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun handleLogoutFromFlutter() {
        Log.d("UpEnte", "Handling logout from Flutter")
        val sharedPrefs = context.getSharedPreferences("ente_prefs", Context.MODE_PRIVATE)
        val editor = sharedPrefs.edit()
        editor.remove("username")
        editor.apply()
        Log.d("UpEnte", "Logout completed from Flutter")
    }

    private fun getCurrentUsernameFromNativePreferences(): String? {
        Log.d("UpEnte", "[DEBUG] About to get current username from native SharedPreferences")
        val sharedPrefs: SharedPreferences = context.getSharedPreferences("ente_prefs", Context.MODE_PRIVATE)
        val username = sharedPrefs.getString("username", null)
        Log.d("UpEnte", "[DEBUG] Retrieved current username from native SharedPreferences: $username")
        return username
    }
} 