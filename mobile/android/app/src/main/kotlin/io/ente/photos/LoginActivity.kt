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
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class LoginActivity : AppCompatActivity() {

    private var account: AccountModel? = null
    private val resultIntent = Intent()

    companion object {
        const val EXTRA_LOGIN_STATUS = "com.unplugged.photos.LOGIN_STATUS"

        private const val ACCOUNT_ACTIVITY_CLASS_NAME =
            "com.unplugged.account.ui.thirdparty.ThirdPartyCredentialsActivity"
        private const val ACCOUNT_PACKAGE_NAME = "com.unplugged.store.dev"
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
                            resultIntent.putExtra(EXTRA_LOGIN_STATUS, true)
                            setResult(Activity.RESULT_OK, resultIntent)
                            Log.d("UpEnte", "Login error: 1")
                            lifecycleScope.launch {

                                val generateCredentialsIntent = Intent().apply {
                                    component = ComponentName(
                                        ACCOUNT_PACKAGE_NAME,
                                        ACCOUNT_ACTIVITY_CLASS_NAME
                                    )
                                    putExtra("action", "generate_credentials")
                                }
                                try {
                                    Log.d("UpEnte", "Login error: 2")

                                    startActivity(generateCredentialsIntent)
                                    finish()
                                } catch (e: ActivityNotFoundException) {
                                    Log.d("UpEnte", "Failed to start account activity for credential generation: $e")
                                    Log.d("UpEnte", "Login error: 3")
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

            handleAccountLoginResponse(account)
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if username is already saved
        val sharedPrefs: SharedPreferences = getSharedPreferences("ente_prefs", MODE_PRIVATE)
        val savedUsername = sharedPrefs.getString("username", null)
        Log.d("UpEnte", "[DEBUG] Read username from native SharedPreferences: $savedUsername")
        if (!savedUsername.isNullOrEmpty()) {
            Log.d("UpEnte", "[DEBUG] Username already saved: $savedUsername, skipping account app call")
            // Username exists, go directly to MainActivity
            resultIntent.putExtra(EXTRA_LOGIN_STATUS, true)
            setResult(Activity.RESULT_OK, resultIntent)
            
            val openFlutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("username", savedUsername)
                // Note: service_password and up_token will be null, but that's okay
                // since we're skipping the account app flow
            }
            startActivity(openFlutterIntent)
            finish()
            return
        }
        
        // No saved username, proceed with normal account app flow
        var launchSuccessful = true
        val credentialsIntent = Intent().apply {
            component = ComponentName(
                ACCOUNT_PACKAGE_NAME,
                ACCOUNT_ACTIVITY_CLASS_NAME
            )
            putExtra("action", "service_1")
        }

        try {
            accountLoginLauncher.launch(credentialsIntent)

        } catch (e: ActivityNotFoundException) {
            Log.d("UpEnte", "RESULT_CANCELED (due to $e)")
            handleAccountLoginResponse()
            launchSuccessful = false

        } catch (e: Exception) {
            Log.d("UpEnte", "RESULT_CANCELED (due to $e)")
            handleAccountLoginResponse()
            launchSuccessful = false
        }

        if (!launchSuccessful) {
            Log.d("UpEnte", "RESULT_CANCELED (due to launch exception)")
            resultIntent.putExtra(EXTRA_LOGIN_STATUS, true)
            setResult(Activity.RESULT_OK, resultIntent)
            finish()
        }
    }

    private fun handleAccountLoginResponse(retrievedAccount: AccountModel? = null) {
        var loginSuccess = false

        if (retrievedAccount != null && retrievedAccount.servicePassword.isNotEmpty()) {
            // Login was successful
            resultIntent.putExtra(EXTRA_LOGIN_STATUS, true)
            Log.d("UpEnte", "Login successful. User: ${account?.username}")
            
            // Username will be saved by Flutter via MethodChannel after Ente authentication succeeds
            Log.d("UpEnte", "Username will be saved by Flutter after Ente authentication")
            
            loginSuccess = true
        } else {
            // Login failed (account is null)
            resultIntent.putExtra(EXTRA_LOGIN_STATUS, false)
            Log.d("UpEnte", "Login failed: Account details null")
            loginSuccess = false
        }

        setResult(Activity.RESULT_OK, resultIntent)

        if (loginSuccess) {
            // Only start MainActivity if the login was actually successful
            Log.d("UpEnte", "Proceeding to MainActivity.")
            val openFlutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("service_password", account?.servicePassword)
                putExtra("up_token", account?.upToken)
                putExtra("username", account?.username)
            }
            startActivity(openFlutterIntent)
        } else {
            Log.d("UpEnte", "Not starting MainActivity because login failed.")
        }

        finish()
    }
}