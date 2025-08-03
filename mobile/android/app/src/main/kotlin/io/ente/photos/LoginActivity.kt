package io.ente.photos

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import android.accounts.AccountManager

class LoginActivity : AppCompatActivity() {

    private var account: AccountModel? = null

    companion object {
        private const val ACCOUNT_ACTIVITY_CLASS_NAME =
            "com.unplugged.account.ui.thirdparty.ThirdPartyCredentialsActivity"

        private fun isDebugBuild(context: android.content.Context): Boolean {
            val isDebug =
                context.packageName.endsWith(".dev") || context.packageName.endsWith(".debug")
            Log.d(
                "UpEnte",
                "[DEBUG] isDebugBuild: packageName=${context.packageName}, isDebug=$isDebug"
            )
            return isDebug
        }
    }

    private val accountLoginLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            when (result.resultCode) {
                Activity.RESULT_OK -> {
                    val servicePassword = result.data?.getStringExtra("service_password") ?: ""
                    val upToken = result.data?.getStringExtra("up_token") ?: ""
                    val usernameRaw = result.data?.getStringExtra("username") ?: ""
                    Log.d("UpEnte", "[AccountApp] service_password: $servicePassword")
                    Log.d("UpEnte", "[AccountApp] up_token: $upToken")
                    Log.d("UpEnte", "[AccountApp] username: $usernameRaw")
                    account = AccountModel(
                        servicePassword,
                        upToken,
                        "$usernameRaw@matrix.unpluggedsystems.app"
                    )
                }

                Activity.RESULT_CANCELED -> {
                    when (result.data?.getStringExtra("reason")) {
                        "USER_REJECTED" -> {
                            Log.d("UpEnte", "Login error: User doesn't want backup")
                        }

                        "NO_CREDENTIALS" -> {
                            Log.d("UpEnte", "Login error: Missing service password")
                            lifecycleScope.launch {
                                val generateCredentialsIntent = Intent().apply {
                                    component = ComponentName(
                                        this@LoginActivity.getString(R.string.account_intent_package),
                                        ACCOUNT_ACTIVITY_CLASS_NAME
                                    )
                                    putExtra("action", "generate_credentials")
                                }
                                try {
                                    startActivity(generateCredentialsIntent)
                                    finish()
                                    return@launch // Exit early to prevent handleAccountLoginResponse from being called
                                } catch (e: ActivityNotFoundException) {
                                    Log.d(
                                        "UpEnte",
                                        "Failed to start account activity for credential generation: $e"
                                    )
                                }
                            }
                        }

                        "NO_SERVICE_NAME_PROVIDED" -> {
                            Log.d("UpEnte", "Login error: Didn't send service name")
                        }

                        "UP_UNAUTHORIZED" -> {
                            Log.d("UpEnte", "Login error: User is not logged in")
                        }
                    }
                }
            }

            // Only call handleAccountLoginResponse if the activity is not finishing
            if (!isFinishing) {
                handleAccountLoginResponse(account)
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        overridePendingTransition(0, 0)
        // Prevent white screen flash
        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
        val sharedPrefs: SharedPreferences = getSharedPreferences("ente_prefs", MODE_PRIVATE)
        val savedUsername = sharedPrefs.getString("username", null)

        Log.d("UpEnte", "[DEBUG] onCreate: savedUsername from SharedPreferences: $savedUsername")

        val accountType =
            if (isDebugBuild(this)) "com.unplugged.account.dev" else "com.unplugged.account"
        Log.d("UpEnte", "[DEBUG] onCreate: accountType used: $accountType")

        val accountManager = AccountManager.get(this)
        val account = accountManager.getAccountsByType(accountType).firstOrNull()
        Log.d(
            "UpEnte",
            "[DEBUG] onCreate: account fetched: $account, name: ${account?.name}, type: ${account?.type}"
        )
        val accountUsername = account?.let { accountManager.getUserData(it, "username") }
        Log.d(
            "UpEnte",
            "[DEBUG] SharedPrefs username: $savedUsername, AccountManager username: $accountUsername"
        )

        if (savedUsername.isNullOrEmpty()) {
            // No previous login, just start account app flow
            Log.d("UpEnte", "[DEBUG] No saved username, starting account app flow")
            val credentialsIntent = Intent().apply {
                component = ComponentName(
                    this@LoginActivity.getString(R.string.account_intent_package),
                    ACCOUNT_ACTIVITY_CLASS_NAME
                )
                putExtra("action", "service_1")
            }
            try {
                accountLoginLauncher.launch(credentialsIntent)
            } catch (e: Exception) {
                Log.d("UpEnte", "Failed to launch account app: $e")
                finish()
            }
            return
        }

        val trimmedSavedUsername = savedUsername.substringBefore('@')
        Log.d(
            "UpEnte",
            "[DEBUG] Comparing trimmedSavedUsername: $trimmedSavedUsername to accountUsername: $accountUsername"
        )
        if (accountUsername.isNullOrEmpty() || trimmedSavedUsername != accountUsername) {
            // Username mismatch or missing in AccountManager, trigger forced logout
            Log.d(
                "UpEnte",
                "[DEBUG] Username missing or mismatch, triggering forced logout via MainActivity"
            )
            val openFlutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("shouldLogout", true)
                // Use REORDER_TO_FRONT to bring existing MainActivity to front if it exists
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(openFlutterIntent)
            finish()
            return
        } else {
            // If both usernames exist and match, go to MainActivity
            Log.d("UpEnte", "[DEBUG] Usernames match, proceeding to MainActivity")
            val openFlutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("username", savedUsername)
                putExtra("from_gallery", true) // Flag to indicate this came from gallery app
                // Use REORDER_TO_FRONT to bring existing MainActivity to front if it exists
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(openFlutterIntent)
            finish()
        }
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }


    private fun handleAccountLoginResponse(retrievedAccount: AccountModel? = null) {
        var loginSuccess = false

        if (retrievedAccount != null && retrievedAccount.servicePassword.isNotEmpty()) {
            // Login was successful
            Log.d("UpEnte", "user is logged in. User: ${account?.username}")
            Log.d("UpEnte", "Username will be saved by Flutter after Ente authentication")
            loginSuccess = true
        } else {
            // Login failed (account is null)
            Log.d("UpEnte", "Login failed: Account details null")
            loginSuccess = false
        }

        if (loginSuccess) {
            // Only start MainActivity if the login was actually successful
            Log.d("UpEnte", "Proceeding to MainActivity.")
            val openFlutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("service_password", account?.servicePassword)
                putExtra("up_token", account?.upToken)
                putExtra("username", account?.username)
                putExtra("from_gallery", true) // Flag to indicate this came from gallery app
                // Use REORDER_TO_FRONT to bring existing MainActivity to front if it exists
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(openFlutterIntent)
            finish()
        } else {
            // open gallery app and finish if login failed (except NO_CREDENTIALS, handled elsewhere)
            Log.d("UpEnte", "Not starting MainActivity because login failed. Opening gallery app.")
            openGalleryApp()
            finish()
        }
    }

    private fun openGalleryApp() {
        val intent = Intent().apply {
            component =
                ComponentName("com.android.gallery3d", "com.android.gallery3d.app.GalleryActivity")
            putExtra("up_photos", "false")
        }
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Log.d("UpEnte", "Gallery app not found, finishing LoginActivity")
            // If gallery app is not available, just finish the activity
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("UpEnte", "onDestroy: ")
    }
}