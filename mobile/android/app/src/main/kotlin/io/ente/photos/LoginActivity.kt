package io.ente.photos

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class LoginActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_LOGIN_STATUS = "com.unplugged.photos.LOGIN_STATUS"
        const val ACTION_CHECK_LOGIN = "com.unplugged.photos.ACTION_CHECK_LOGIN"

        private const val ACCOUNT_ACTION_REQUEST_CREDENTIALS = "com.example.app3.ACTION_REQUEST_CREDENTIALS"
        private const val ACCOUNT_ACTIVITY_CLASS_NAME = "com.unplugged.account.ui.thirdparty.ThirdPartyCredentialsActivity"
        private const val ACCOUNT_PACKAGE_NAME = "com.unplugged.account"
        private const val ACCOUNT_EXTRA_LOGIN_SUCCESS_RESULT = "com.unplugged.account.EXTRA_LOGIN_SUCCESS_RESULT"
    }

    private val accountLoginLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            var isLoginSuccessful = false
            if (result.resultCode == Activity.RESULT_OK) {
                isLoginSuccessful = result.data?.getBooleanExtra(ACCOUNT_EXTRA_LOGIN_SUCCESS_RESULT, false) ?: false
            }
            handleAccountLoginResponse(isLoginSuccessful)
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (intent?.action == ACTION_CHECK_LOGIN) {
            // Proceed with launching the third-party app for login
            val loginIntent = Intent().apply {
                component = ComponentName(ACCOUNT_PACKAGE_NAME, ACCOUNT_ACTIVITY_CLASS_NAME)
                action = ACCOUNT_ACTION_REQUEST_CREDENTIALS
            }

            try {
                accountLoginLauncher.launch(loginIntent)
            } catch (e: ActivityNotFoundException) {
                handleAccountLoginResponse(false)
            } catch (e: Exception) {
                handleAccountLoginResponse(false)
            }
        } else {
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    private fun handleAccountLoginResponse(isLoginSuccessful: Boolean) {
        val resultIntent = Intent()
        resultIntent.putExtra(EXTRA_LOGIN_STATUS, isLoginSuccessful)
        setResult(Activity.RESULT_OK, resultIntent)

        if (isLoginSuccessful) {
            val openFlutterIntent = Intent(this, MainActivity::class.java)
            openFlutterIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(openFlutterIntent)
        }
        finish()
    }
}