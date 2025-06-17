package io.ente.photos

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class LoginActivity : AppCompatActivity() {

    private var account: AccountModel? = null

    companion object {
        const val EXTRA_LOGIN_STATUS = "com.unplugged.photos.LOGIN_STATUS"

        private const val ACCOUNT_ACTIVITY_CLASS_NAME =
            "com.unplugged.account.ui.thirdparty.ThirdPartyCredentialsActivity"
        private const val ACCOUNT_PACKAGE_NAME = "com.unplugged.accountsample.dev"
    }

    private val accountLoginLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == Activity.RESULT_OK) {
                account = AccountModel(
                    result.data?.getStringExtra("service_password") ?: "",
                    result.data?.getStringExtra("up_token") ?: "",
                    result.data?.getStringExtra("username") ?: ""
                )
            }
            handleAccountLoginResponse(account)
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val credentialsIntent = Intent().apply {
            component = ComponentName(
                ACCOUNT_PACKAGE_NAME, // Assuming these constants are defined in the class
                ACCOUNT_ACTIVITY_CLASS_NAME
            )
            putExtra("service_name", "service_1")
        }

        var launchSuccessful = false
        try {
            accountLoginLauncher.launch(credentialsIntent)
            launchSuccessful = true // Assume success if no exception
        } catch (e: ActivityNotFoundException) {
            Log.d("LoginActivity", "RESULT_CANCELED (due to $e)")
            handleAccountLoginResponse()
            // launchSuccessful remains false
        } catch (e: Exception) {
            Log.d("LoginActivity", "RESULT_CANCELED (due to $e)")
            handleAccountLoginResponse()
            // launchSuccessful remains false
        }

        if (!launchSuccessful) { // This is an interpretation of what the 'else' might have meant
            Log.d("LoginActivity", "RESULT_CANCELED (due to launch exception)")
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    private fun handleAccountLoginResponse(retrievedAccount: AccountModel? = null) {
        val resultIntent = Intent()
        var loginSuccess = false

        if (retrievedAccount != null && retrievedAccount.servicePassword.isNotEmpty()) {
            // Login was successful
            account = retrievedAccount // Store the valid account details
            resultIntent.putExtra(EXTRA_LOGIN_STATUS, true)
            Log.d("LoginActivity", "Login successful. User: ${account?.username}")
            setResult(Activity.RESULT_OK, resultIntent)
            loginSuccess = true
        } else {
            // Login failed (account is null or password empty)
            account = null
            resultIntent.putExtra(EXTRA_LOGIN_STATUS, false)
            val reason = if (retrievedAccount == null) "Account details null" else "ServicePassword empty"
            Log.d("LoginActivity", "Login failed: $reason")
            setResult(Activity.RESULT_CANCELED, resultIntent) // Set result to CANCELED for failure
            loginSuccess = false
        }

        if (loginSuccess) {
            // Only start MainActivity if the login was actually successful
            Log.d("LoginActivity", "Proceeding to MainActivity.")
            val openFlutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("service_password", account?.servicePassword)
                putExtra("up_token", account?.upToken)
                putExtra("username", account?.username)
            }
            startActivity(openFlutterIntent)
        } else {
            Log.d("LoginActivity", "Not starting MainActivity because login failed.")
        }

        finish()
    }
}