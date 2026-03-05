@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu.auth

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import io.ente.ensu.data.auth.AuthResponsePayload
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.auth.KeyAttributes
import io.ente.ensu.data.auth.PasskeySessionExpiredException
import io.ente.ensu.data.auth.PasskeySessionNotVerifiedException
import io.ente.ensu.data.auth.SrpAttributes
import io.ente.ensu.data.auth.SrpLoginResult
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import kotlinx.coroutines.launch

@Composable
internal fun EmailEntryView(
    authService: EnsuAuthService,
    onNavigate: (AuthRoute) -> Unit
) {
    var email by remember { mutableStateOf("") }
    val authState = rememberAuthActionState()
    val isEmailValid = email.trim().contains("@") && email.trim().contains(".") && email.trim().length >= 5

    AuthScreen(
        content = {
            AuthHeader(title = "Welcome back")
            Column(verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(EnsuSpacing.lg.dp)) {
                LabeledTextField(
                    label = "Email",
                    hint = "Enter your email",
                    value = email,
                    onValueChange = { email = it },
                    keyboardType = KeyboardType.Email
                )
                if (authState.errorMessage != null) {
                    Text(
                        text = authState.errorMessage.orEmpty(),
                        style = EnsuTypography.small,
                        color = EnsuColor.error,
                        modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                    )
                }
            }
        },
        bottom = {
            PrimaryButton(
                text = "Log in",
                isLoading = authState.isLoading,
                isEnabled = isEmailValid && !authState.isLoading
            ) {
                authState.launch(onError = { error ->
                    when (error) {
                        is io.ente.ensu.data.auth.AccountNotFoundException ->
                            "No account found for this email."
                        else -> "Failed to get account info: ${error.message}"
                    }
                }) {
                    val trimmed = email.trim()
                    val srpAttrs = authService.getSrpAttributes(trimmed)
                    if (srpAttrs.isEmailMfaEnabled) {
                        authService.sendOtp(trimmed)
                        onNavigate(AuthRoute.Otp(trimmed, srpAttrs))
                    } else {
                        onNavigate(AuthRoute.Password(trimmed, srpAttrs))
                    }
                }
            }
        }
    )
}

@Composable
internal fun PasswordView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    val authState = rememberAuthActionState()
    val hasPassword = password.isNotBlank()

    AuthScreen(
        content = {
            AuthHeader(title = "Enter password")
            AuthSubtitle(text = email)
            Spacer(modifier = Modifier.height(EnsuSpacing.xxl.dp))
            PasswordTextField(
                label = "Password",
                hint = "Enter your password",
                value = password,
                onValueChange = { password = it },
                showPassword = showPassword,
                onTogglePassword = { showPassword = !showPassword }
            )
            if (authState.errorMessage != null) {
                Text(
                    text = authState.errorMessage.orEmpty(),
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            }
        },
        bottom = {
            PrimaryButton(
                text = "Log in",
                isLoading = authState.isLoading,
                isEnabled = hasPassword && !authState.isLoading
            ) {
                authState.launch {
                    val result = authService.loginWithSrp(email, password, srpAttributes)
                    handleSrpResult(result, email, srpAttributes, password, onNavigate, onLoggedIn)
                }
            }
        }
    )
}

@Composable
internal fun OtpVerificationView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    onNavigate: (AuthRoute) -> Unit
) {
    var code by remember { mutableStateOf("") }
    val authState = rememberAuthActionState()
    val scope = rememberCoroutineScope()
    val hasValidCode = code.trim().length == 6

    fun submitOtp() {
        if (!hasValidCode || authState.isLoading) return
        authState.launch {
            val payload = authService.verifyOtp(email, code)
            val keyAttrs = payload.keyAttributes
            if (keyAttrs == null) {
                setError("New user signup not implemented. Please use an existing account.")
            } else if (payload.requiresPasskey) {
                onNavigate(
                    AuthRoute.Passkey(
                        email = email,
                        srp = srpAttributes,
                        sessionId = payload.passkeySessionId.orEmpty(),
                        accountsUrl = payload.accountsUrl ?: "https://accounts.ente.io",
                        twoFactorSessionId = payload.twoFactorSessionId,
                        password = null
                    )
                )
            } else if (payload.requiresTwoFactor) {
                onNavigate(
                    AuthRoute.TwoFactor(
                        email = email,
                        srp = srpAttributes,
                        sessionId = payload.twoFactorSessionId.orEmpty(),
                        password = null
                    )
                )
            } else {
                onNavigate(
                    AuthRoute.PasswordAfterMfa(
                        email = email,
                        srp = srpAttributes,
                        userId = payload.userId,
                        keyAttributes = keyAttrs,
                        encryptedToken = payload.encryptedToken,
                        token = payload.token
                    )
                )
            }
        }
    }

    LaunchedEffect(code) {
        if (code.trim().length == 6) {
            submitOtp()
        }
    }

    AuthScreen(
        content = {
            AuthHeader(title = "Verify email", subtitle = email)
            Column(verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(EnsuSpacing.lg.dp)) {
                CodeTextField(
                    value = code,
                    onValueChange = { code = it },
                    onComplete = { value -> if (value.length == 6) code = value }
                )
                TextLink(text = "Resend code") {
                    scope.launch {
                        runCatching { authService.sendOtp(email) }
                            .onFailure { authState.setError("Failed to resend code: ${it.message}") }
                    }
                }
                if (authState.errorMessage != null) {
                    Text(
                        text = authState.errorMessage.orEmpty(),
                        style = EnsuTypography.small,
                        color = EnsuColor.error,
                        modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                    )
                }
            }
        },
        bottom = {
            PrimaryButton(
                text = "Verify",
                isLoading = authState.isLoading,
                isEnabled = hasValidCode && !authState.isLoading
            ) {
                submitOtp()
            }
        }
    )
}

@Composable
internal fun TwoFactorView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    sessionId: String,
    password: String?,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    var code by remember { mutableStateOf("") }
    val authState = rememberAuthActionState()
    val hasValidCode = code.trim().length == 6

    fun submitTwoFactor() {
        if (!hasValidCode || authState.isLoading) return
        authState.launch {
            val payload = authService.verifyTwoFactor(sessionId, code)
            val keyAttrs = payload.keyAttributes
            if (keyAttrs == null) {
                setError("Invalid response")
            } else if (!password.isNullOrBlank()) {
                authService.loginAfterChallenge(
                    email = email,
                    password = password,
                    srpAttributes = srpAttributes,
                    userId = payload.userId,
                    keyAttributes = keyAttrs,
                    encryptedToken = payload.encryptedToken,
                    token = payload.token
                )
                onLoggedIn()
            } else {
                onNavigate(
                    AuthRoute.PasswordAfterMfa(
                        email = email,
                        srp = srpAttributes,
                        userId = payload.userId,
                        keyAttributes = keyAttrs,
                        encryptedToken = payload.encryptedToken,
                        token = payload.token
                    )
                )
            }
        }
    }

    LaunchedEffect(code) {
        if (code.trim().length == 6) {
            submitTwoFactor()
        }
    }

    AuthScreen(
        content = {
            AuthHeader(
                title = "Two-factor authentication",
                subtitle = "Enter the code from your authenticator app"
            )
            Column(verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(EnsuSpacing.lg.dp)) {
                CodeTextField(
                    value = code,
                    onValueChange = { code = it },
                    onComplete = { value -> if (value.length == 6) code = value }
                )
                if (authState.errorMessage != null) {
                    Text(
                        text = authState.errorMessage.orEmpty(),
                        style = EnsuTypography.small,
                        color = EnsuColor.error,
                        modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                    )
                }
            }
        },
        bottom = {
            PrimaryButton(
                text = "Verify",
                isLoading = authState.isLoading,
                isEnabled = hasValidCode && !authState.isLoading
            ) {
                submitTwoFactor()
            }
        }
    )
}

@Composable
internal fun PasskeyView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    sessionId: String,
    accountsUrl: String,
    twoFactorSessionId: String?,
    password: String?,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    val context = LocalContext.current
    val authState = rememberAuthActionState()

    LaunchedEffect(sessionId) {
        launchPasskey(context, accountsUrl, sessionId)
    }

    AuthScreen(
        content = {
            AuthHeader(
                title = "Passkey verification",
                subtitle = "Complete passkey verification in browser"
            )
            Column(verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(EnsuSpacing.lg.dp)) {
                TextLink(text = "Open passkey again") {
                    launchPasskey(context, accountsUrl, sessionId)
                }

                if (!twoFactorSessionId.isNullOrBlank()) {
                    TextLink(text = "Use authenticator code") {
                        onNavigate(
                            AuthRoute.TwoFactor(
                                email = email,
                                srp = srpAttributes,
                                sessionId = twoFactorSessionId,
                                password = password
                            )
                        )
                    }
                }

                if (authState.errorMessage != null) {
                    Text(
                        text = authState.errorMessage.orEmpty(),
                        style = EnsuTypography.small,
                        color = EnsuColor.textMuted(),
                        modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                    )
                }
            }
        },
        bottom = {
            PrimaryButton(
                text = "Check status",
                isLoading = authState.isLoading,
                isEnabled = !authState.isLoading
            ) {
                authState.launch(onError = { "Failed to check passkey status: ${it.message}" }) {
                    try {
                        val payload = authService.getTokenForPasskeySession(sessionId)
                        handlePasskeyAuthResponse(
                            authService = authService,
                            payload = payload,
                            email = email,
                            srpAttributes = srpAttributes,
                            password = password,
                            onNavigate = onNavigate,
                            onLoggedIn = onLoggedIn
                        )
                    } catch (error: PasskeySessionNotVerifiedException) {
                        setError("Passkey verification is still pending.")
                    } catch (error: PasskeySessionExpiredException) {
                        setError("Login session expired.")
                    }
                }
            }
        }
    )
}

@Composable
internal fun PasswordAfterMfaView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    userId: Long,
    keyAttributes: KeyAttributes,
    encryptedToken: String?,
    token: String?,
    onLoggedIn: () -> Unit
) {
    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    val authState = rememberAuthActionState()

    AuthScreen(
        content = {
            AuthHeader(title = "Enter password")
            AuthSubtitle(text = email)
            Spacer(modifier = Modifier.height(EnsuSpacing.xxl.dp))
            PasswordTextField(
                label = "Password",
                hint = "Enter your password",
                value = password,
                onValueChange = { password = it },
                showPassword = showPassword,
                onTogglePassword = { showPassword = !showPassword }
            )
            if (authState.errorMessage != null) {
                Text(
                    text = authState.errorMessage.orEmpty(),
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            }
        },
        bottom = {
            PrimaryButton(
                text = "Continue",
                isLoading = authState.isLoading,
                isEnabled = password.isNotBlank() && !authState.isLoading
            ) {
                authState.launch(onError = { "Incorrect password: ${it.message}" }) {
                    authService.loginAfterChallenge(
                        email = email,
                        password = password,
                        srpAttributes = srpAttributes,
                        userId = userId,
                        keyAttributes = keyAttributes,
                        encryptedToken = encryptedToken,
                        token = token
                    )
                    onLoggedIn()
                }
            }
        }
    )
}

@Composable
internal fun PasskeyPasswordReentryView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    auth: AuthResponsePayload,
    onLoggedIn: () -> Unit
) {
    val keyAttributes = auth.keyAttributes
    if (keyAttributes == null) {
        AuthScreen(
            content = {
                AuthHeader(title = "Enter password")
                AuthSubtitle(text = email)
                Text(
                    text = "Invalid passkey response",
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            },
            bottom = { }
        )
        return
    }

    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    val authState = rememberAuthActionState()

    AuthScreen(
        content = {
            AuthHeader(title = "Enter password")
            AuthSubtitle(text = email)
            Spacer(modifier = Modifier.height(EnsuSpacing.xxl.dp))
            PasswordTextField(
                label = "Password",
                hint = "Enter your password",
                value = password,
                onValueChange = { password = it },
                showPassword = showPassword,
                onTogglePassword = { showPassword = !showPassword }
            )
            if (authState.errorMessage != null) {
                Text(
                    text = authState.errorMessage.orEmpty(),
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            }
        },
        bottom = {
            PrimaryButton(
                text = "Continue",
                isLoading = authState.isLoading,
                isEnabled = password.isNotBlank() && !authState.isLoading
            ) {
                authState.launch(onError = { "Incorrect password: ${it.message}" }) {
                    authService.loginAfterChallenge(
                        email = email,
                        password = password,
                        srpAttributes = srpAttributes,
                        userId = auth.userId,
                        keyAttributes = keyAttributes,
                        encryptedToken = auth.encryptedToken,
                        token = auth.token
                    )
                    onLoggedIn()
                }
            }
        }
    )
}

private class AuthActionState(private val scope: kotlinx.coroutines.CoroutineScope) {
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    fun setError(message: String?) {
        errorMessage = message
    }

    fun launch(
        onError: (Throwable) -> String? = { it.message },
        block: suspend AuthActionState.() -> Unit
    ) {
        if (isLoading) return
        scope.launch {
            if (isLoading) return@launch
            isLoading = true
            errorMessage = null
            try {
                block()
            } catch (error: Throwable) {
                errorMessage = onError(error)
            } finally {
                isLoading = false
            }
        }
    }
}

@Composable
private fun rememberAuthActionState(): AuthActionState {
    val scope = rememberCoroutineScope()
    return remember(scope) { AuthActionState(scope) }
}

private fun handleSrpResult(
    result: SrpLoginResult,
    email: String,
    srpAttributes: SrpAttributes,
    password: String,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    if (result.requiresPasskey) {
        onNavigate(
            AuthRoute.Passkey(
                email = email,
                srp = srpAttributes,
                sessionId = result.passkeySessionId.orEmpty(),
                accountsUrl = result.accountsUrl ?: "https://accounts.ente.io",
                twoFactorSessionId = result.twoFactorSessionId,
                password = password
            )
        )
        return
    }

    if (result.requiresTwoFactor) {
        onNavigate(
            AuthRoute.TwoFactor(
                email = email,
                srp = srpAttributes,
                sessionId = result.twoFactorSessionId.orEmpty(),
                password = password
            )
        )
        return
    }

    onLoggedIn()
}

private suspend fun handlePasskeyAuthResponse(
    authService: EnsuAuthService,
    payload: AuthResponsePayload,
    email: String,
    srpAttributes: SrpAttributes,
    password: String?,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    val keyAttrs = payload.keyAttributes ?: return
    if (!password.isNullOrBlank()) {
        authService.loginAfterChallenge(
            email = email,
            password = password,
            srpAttributes = srpAttributes,
            userId = payload.userId,
            keyAttributes = keyAttrs,
            encryptedToken = payload.encryptedToken,
            token = payload.token
        )
        onLoggedIn()
    } else {
        onNavigate(AuthRoute.PasskeyPasswordReentry(email, srpAttributes, payload))
    }
}

private fun launchPasskey(context: android.content.Context, accountsUrl: String, sessionId: String) {
    val base = accountsUrl.trimEnd('/')
    val url = Uri.parse("$base/passkeys/verify")
        .buildUpon()
        .appendQueryParameter("passkeySessionID", sessionId)
        .appendQueryParameter("redirect", "enteensu://passkey")
        .appendQueryParameter("clientPackage", context.packageName)
        .build()

    val intent = Intent(Intent.ACTION_VIEW, url)
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    context.startActivity(intent)
}
