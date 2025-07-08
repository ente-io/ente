package io.ente.photos

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity // Your existing base class
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant // Keep this

class MainActivity : FlutterFragmentActivity() {
    private val ACCOUNT_CHANNEL_NAME = "com.unplugged.photos/account"
    private var methodChannel: MethodChannel? = null

    private var pendingAccountDetails: Map<String, String>? = null


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("UpEnte", "configureFlutterEngine called")

        GeneratedPluginRegistrant.registerWith(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCOUNT_CHANNEL_NAME)

        // Handle method calls from Dart
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAccount" -> {
                    if (pendingAccountDetails != null) {
                        sendAccountDetailsToFlutter(pendingAccountDetails!!)
                        pendingAccountDetails = null
                        result.success(null)
                    } else {
                        Log.d("UpEnte", "No pending account details to send.")
                        result.success(null)
                    }
                }
                else -> {
                    Log.w("UpEnte", "Unknown method from Flutter: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // If account details were pending before the methodChannel was initialized, send them now
        pendingAccountDetails?.let { details ->
            sendAccountDetailsToFlutter(details)
            pendingAccountDetails = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle intent if MainActivity is already running (e.g., singleTask or reordered to front)
        setIntent(intent) // Important: update the activity's current intent
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {

        val servicePassword = intent?.getStringExtra("service_password")
        val upToken = intent?.getStringExtra("up_token")
        val username = intent?.getStringExtra("username")

        Log.d("UpEnte", "handleIntent: received service_password=$servicePassword, up_token=$upToken, username=$username")

        if (servicePassword != null && upToken != null && username != null) {
            val accountDetails = mapOf(
                "service_password" to servicePassword,
                "up_token" to upToken,
                "username" to username
            )

            // Check if methodChannel is initialized (meaning configureFlutterEngine has run)
            if (methodChannel != null) {
                // Flutter engine is configured, send data directly
                sendAccountDetailsToFlutter(accountDetails)
            } else {
                // Flutter engine not configured yet, or methodChannel not set up.
                // Store data to send when configureFlutterEngine is called.
                pendingAccountDetails = accountDetails
            }
        }
    }

    private fun sendAccountDetailsToFlutter(accountDetails: Map<String, String>) {
        methodChannel?.invokeMethod("onAccountReceived", accountDetails, object : MethodChannel.Result {
            override fun success(result: Any?) {
                 Log.d("UpEnte", "Account details sent to Flutter successfully.")
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                 Log.e("UpEnte", "Failed to send account details: $errorCode $errorMessage")
            }

            override fun notImplemented() {
                 Log.w("UpEnte", "onAccountReceived not implemented on Dart side.")
            }
        })
    }

    override fun onDestroy() {
        methodChannel = null // Clean up the channel
        super.onDestroy()
    }
}