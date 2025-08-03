package io.ente.photos

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity // Your existing base class
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant // Keep this
import android.accounts.AccountManager

class MainActivity : FlutterFragmentActivity() {
    // Channel for receiving account details from LoginActivity
    private val ACCOUNT_CHANNEL_NAME = "com.unplugged.photos/account"
    private var methodChannel: MethodChannel? = null
    private lateinit var methodChannelHandler: MethodChannelHandler

    private var pendingAccountDetails: Map<String, String>? = null

    private lateinit var accountManager: AccountManager

    private var pendingLogoutRestart = false
    private var pendingShouldLogout = false

    companion object {
        private const val LOGOUT_CHANNEL_NAME = "ente_logout_channel"
    }

    private var logoutChannel: MethodChannel? = null


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("UpEnte", "configureFlutterEngine called")

        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Initialize MethodChannelHandler
        methodChannelHandler = MethodChannelHandler()
        methodChannelHandler.onAttachedToEngine(flutterEngine.dartExecutor.binaryMessenger)
        methodChannelHandler.setActivity(this)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCOUNT_CHANNEL_NAME)
        logoutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOGOUT_CHANNEL_NAME)

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

        // Add handler for logoutComplete from Flutter
        val logoutCompleteChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ente_logout_complete_channel")
        logoutCompleteChannel.setMethodCallHandler { call, result ->
            if (call.method == "logoutComplete") {
                Log.d("UpEnte", "[DEBUG] Received logoutComplete from Flutter, restarting LoginActivity")
                pendingLogoutRestart = false
                val loginIntent = Intent(this, LoginActivity::class.java)
                startActivity(loginIntent)
                finish()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // After engine is ready, process any pending logout
        if (pendingShouldLogout) {
            Log.d("UpEnte", "[DEBUG] Sending pending logout to Flutter after engine ready")
            val logoutChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ente_logout_channel")
            logoutChannel.invokeMethod("onLogoutRequested", null)
            pendingShouldLogout = false
        }

        // If account details were pending before the methodChannel was initialized, send them now
        pendingAccountDetails?.let { details ->
            sendAccountDetailsToFlutter(details)
            pendingAccountDetails = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        overridePendingTransition(0,0)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle intent if MainActivity is already running (e.g., singleTask or reordered to front)
        Log.d("UpEnte", "[DEBUG] onNewIntent called - MainActivity brought to front")
        setIntent(intent) // Important: update the activity's current intent
        
        // Notify Flutter if this is a reorder-to-front scenario from gallery app
        if (intent.getBooleanExtra("from_gallery", false)) {
            Log.d("UpEnte", "[DEBUG] MainActivity brought to front from gallery app")
            methodChannel?.invokeMethod("onBroughtToFront", null)
        }
        
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {

        val servicePassword = intent?.getStringExtra("service_password")
        val upToken = intent?.getStringExtra("up_token")
        val username = intent?.getStringExtra("username")

        Log.d("UpEnte", "handleIntent: received service_password=$servicePassword, up_token=$upToken, username=$username")
        
        // If this is a reorder-to-front scenario and we already have account details, 
        // we might want to refresh the Flutter side
        if (servicePassword == null && upToken == null && username == null && 
            intent?.getBooleanExtra("shouldLogout", false) != true) {
            Log.d("UpEnte", "[DEBUG] MainActivity brought to front without new account data - likely reorder scenario")
            // Optionally refresh Flutter state or do nothing to keep existing state
            return
        }

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

        if (intent?.getBooleanExtra("shouldLogout", false) == true && !pendingLogoutRestart) {
            Log.d("UpEnte", "[DEBUG] shouldLogout received, will send logout to Flutter after engine is ready")
            pendingLogoutRestart = true
            pendingShouldLogout = true
            // Do NOT call MethodChannel here!
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

    fun handleLogoutFromFlutter() {
        Log.d("UpEnte", "Handling logout from Flutter")
        val sharedPrefs = getSharedPreferences("ente_prefs", MODE_PRIVATE)
        val editor = sharedPrefs.edit()
        editor.remove("username")
        editor.apply()
        Log.d("UpEnte", "Closing app after logout from Flutter")
        finishAndRemoveTask()
    }

    override fun onStart() {
        super.onStart()
        accountManager = AccountManager.get(this)
        val packageName = applicationContext.packageName
        val accountType = if (packageName.contains("dev") || packageName.contains("debug")) {
            "com.unplugged.account.dev"
        } else {
            "com.unplugged.account"
        }

        val sharedPrefs = getSharedPreferences("ente_prefs", MODE_PRIVATE)
        val savedUsername = sharedPrefs.getString("username", null)
        val accountsInSystem = accountManager.accounts
        // Only check account state, do not trigger logout to Flutter here
        // If needed, start login flow or clear state, but do not send onLogoutRequested
        // All forced logout is now handled via shouldLogout intent
        Log.d("UpEnte", "[DEBUG] onStart: username in prefs: $savedUsername, accounts: ${accountsInSystem.map { it.name }}")
        if (savedUsername != null && savedUsername.isNotEmpty()) {
            if (accountsInSystem.none { it.type == accountType }) {
                Log.d("UpEnte", "[DEBUG] No account found on start, requesting logout in Flutter")
                val logoutChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "ente_logout_channel")
                logoutChannel.invokeMethod("onLogoutRequested", null)
            } else {
                val account = accountsInSystem.firstOrNull { it.type == accountType }
                val username = account?.let { accountManager.getUserData(it, "username") }
                val trimmedSavedUsername = savedUsername?.substringBefore('@')
                Log.d("UpEnte", "[DEBUG] Comparing trimmedSavedUsername: $trimmedSavedUsername to accountUsername: $username")
                if (username != trimmedSavedUsername) {
                    Log.d("UpEnte", "[DEBUG] Username mismatch on start, requesting logout in Flutter")
                    val logoutChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "ente_logout_channel")
                    logoutChannel.invokeMethod("onLogoutRequested", null)
                }
            }
        } else {
            Log.d("UpEnte", "[DEBUG] No saved username, not triggering logout")
        }

        // Register listener for future changes
        accountManager.addOnAccountsUpdatedListener({ accountsInSystem ->
            // Only check account state, do not trigger logout to Flutter here
            // All forced logout is now handled via shouldLogout intent
            Log.d("UpEnte", "[DEBUG] AccountManager listener: accounts: ${accountsInSystem.map { it.name }}")
        }, null, false)
        Log.d("UpEnte", "[DEBUG] Registered AccountManager listener for $accountType")
    }

    private fun triggerLogoutToFlutter() {
        Log.d("UpEnte", "[DEBUG] Sending logout request to Flutter via MethodChannel")
        val logoutChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "ente_logout_channel")
        logoutChannel.invokeMethod("onLogoutRequested", null)
        val sharedPrefs = getSharedPreferences("ente_prefs", MODE_PRIVATE)
        sharedPrefs.edit().remove("username").apply()
        Log.d("UpEnte", "[DEBUG] Cleared username from native SharedPreferences")
        finishAndRemoveTask()
    }

    override fun onDestroy() {
        methodChannel = null // Clean up the channel
        if (::methodChannelHandler.isInitialized) {
            methodChannelHandler.onDetachedFromEngine()
        }
        logoutChannel = null // Clean up the logout channel
        super.onDestroy()
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }
}