@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu.auth

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.height
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
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

sealed class AuthRoute {
    data object EmailEntry : AuthRoute()
    data class Otp(val email: String, val srp: SrpAttributes) : AuthRoute()
    data class Password(val email: String, val srp: SrpAttributes) : AuthRoute()
    data class TwoFactor(
        val email: String,
        val srp: SrpAttributes,
        val sessionId: String,
        val password: String?
    ) : AuthRoute()

    data class Passkey(
        val email: String,
        val srp: SrpAttributes,
        val sessionId: String,
        val accountsUrl: String,
        val twoFactorSessionId: String?,
        val password: String?
    ) : AuthRoute()

    data class PasswordAfterMfa(
        val email: String,
        val srp: SrpAttributes,
        val userId: Long,
        val keyAttributes: KeyAttributes,
        val encryptedToken: String?,
        val token: String?
    ) : AuthRoute()

    data class PasskeyPasswordReentry(
        val email: String,
        val srp: SrpAttributes,
        val auth: AuthResponsePayload
    ) : AuthRoute()
}

@Composable
fun AuthFlowScreen(
    authService: EnsuAuthService,
    onLoggedIn: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val backStack = remember { mutableStateListOf<AuthRoute>() }
    val currentRoute = backStack.lastOrNull() ?: AuthRoute.EmailEntry
    val canGoBack = backStack.isNotEmpty()

    Scaffold(
        containerColor = EnsuColor.backgroundBase(),
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        text = "ensu",
                        style = EnsuTypography.h3Bold,
                        color = EnsuColor.textPrimary()
                    )
                },
                navigationIcon = {
                    IconButton(onClick = {
                        if (canGoBack) {
                            backStack.removeLast()
                        } else {
                            onDismiss()
                        }
                    }) {
                        Icon(imageVector = Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {},
                colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (val route = currentRoute) {
                AuthRoute.EmailEntry -> EmailEntryView(
                    authService = authService,
                    onNavigate = { backStack.add(it) }
                )

                is AuthRoute.Otp -> OtpVerificationView(
                    authService = authService,
                    email = route.email,
                    srpAttributes = route.srp,
                    onNavigate = { backStack.add(it) }
                )

                is AuthRoute.Password -> PasswordView(
                    authService = authService,
                    email = route.email,
                    srpAttributes = route.srp,
                    onNavigate = { backStack.add(it) },
                    onLoggedIn = { onLoggedIn(route.email) }
                )

                is AuthRoute.TwoFactor -> TwoFactorView(
                    authService = authService,
                    email = route.email,
                    srpAttributes = route.srp,
                    sessionId = route.sessionId,
                    password = route.password,
                    onNavigate = { backStack.add(it) },
                    onLoggedIn = { onLoggedIn(route.email) }
                )

                is AuthRoute.Passkey -> PasskeyView(
                    authService = authService,
                    email = route.email,
                    srpAttributes = route.srp,
                    sessionId = route.sessionId,
                    accountsUrl = route.accountsUrl,
                    twoFactorSessionId = route.twoFactorSessionId,
                    password = route.password,
                    onNavigate = { backStack.add(it) },
                    onLoggedIn = { onLoggedIn(route.email) }
                )

                is AuthRoute.PasswordAfterMfa -> PasswordAfterMfaView(
                    authService = authService,
                    email = route.email,
                    srpAttributes = route.srp,
                    userId = route.userId,
                    keyAttributes = route.keyAttributes,
                    encryptedToken = route.encryptedToken,
                    token = route.token,
                    onLoggedIn = { onLoggedIn(route.email) }
                )

                is AuthRoute.PasskeyPasswordReentry -> PasskeyPasswordReentryView(
                    authService = authService,
                    email = route.email,
                    srpAttributes = route.srp,
                    auth = route.auth,
                    onLoggedIn = { onLoggedIn(route.email) }
                )
            }
        }
    }
}

@Composable
private fun EmailEntryView(
    authService: EnsuAuthService,
    onNavigate: (AuthRoute) -> Unit
) {
    var email by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val isEmailValid = email.trim().contains("@") && email.trim().contains(".") && email.trim().length >= 5
    val scope = rememberCoroutineScope()

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
                if (errorMessage != null) {
                    Text(
                        text = errorMessage.orEmpty(),
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
                isLoading = isLoading,
                isEnabled = isEmailValid && !isLoading
            ) {
                scope.launch {
                    if (isLoading) return@launch
                    isLoading = true
                    errorMessage = null
                    try {
                        val trimmed = email.trim()
                        val srpAttrs = authService.getSrpAttributes(trimmed)
                        if (srpAttrs.isEmailMfaEnabled) {
                            authService.sendOtp(trimmed)
                            onNavigate(AuthRoute.Otp(trimmed, srpAttrs))
                        } else {
                            onNavigate(AuthRoute.Password(trimmed, srpAttrs))
                        }
                    } catch (error: Exception) {
                        errorMessage = "Failed to get account info: ${error.message}"
                    } finally {
                        isLoading = false
                    }
                }
            }
        }
    )
}

@Composable
private fun PasswordView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
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
            if (errorMessage != null) {
                Text(
                    text = errorMessage.orEmpty(),
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            }
        },
        bottom = {
            PrimaryButton(
                text = "Log in",
                isLoading = isLoading,
                isEnabled = hasPassword && !isLoading
            ) {
                scope.launch {
                    if (isLoading) return@launch
                    isLoading = true
                    errorMessage = null
                    try {
                        val result = authService.loginWithSrp(email, password, srpAttributes)
                        handleSrpResult(result, email, srpAttributes, password, onNavigate, onLoggedIn)
                    } catch (error: Exception) {
                        errorMessage = error.message
                    } finally {
                        isLoading = false
                    }
                }
            }
        }
    )
}

@Composable
private fun OtpVerificationView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    onNavigate: (AuthRoute) -> Unit
) {
    var code by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val hasValidCode = code.trim().length == 6

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
                            .onFailure { errorMessage = "Failed to resend code: ${it.message}" }
                    }
                }
                if (errorMessage != null) {
                    Text(
                        text = errorMessage.orEmpty(),
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
                isLoading = isLoading,
                isEnabled = hasValidCode && !isLoading
            ) {
                scope.launch {
                    if (isLoading) return@launch
                    isLoading = true
                    errorMessage = null
                    try {
                        val payload = authService.verifyOtp(email, code)
                        val keyAttrs = payload.keyAttributes
                        if (keyAttrs == null) {
                            errorMessage = "New user signup not implemented. Please use an existing account."
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
                    } catch (error: Exception) {
                        errorMessage = error.message
                    } finally {
                        isLoading = false
                    }
                }
            }
        }
    )
}

@Composable
private fun TwoFactorView(
    authService: EnsuAuthService,
    email: String,
    srpAttributes: SrpAttributes,
    sessionId: String,
    password: String?,
    onNavigate: (AuthRoute) -> Unit,
    onLoggedIn: () -> Unit
) {
    var code by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val hasValidCode = code.trim().length == 6

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
                if (errorMessage != null) {
                    Text(
                        text = errorMessage.orEmpty(),
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
                isLoading = isLoading,
                isEnabled = hasValidCode && !isLoading
            ) {
                scope.launch {
                    if (isLoading) return@launch
                    isLoading = true
                    errorMessage = null
                    try {
                        val payload = authService.verifyTwoFactor(sessionId, code)
                        val keyAttrs = payload.keyAttributes
                        if (keyAttrs == null) {
                            errorMessage = "Invalid response"
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
                    } catch (error: Exception) {
                        errorMessage = error.message
                    } finally {
                        isLoading = false
                    }
                }
            }
        }
    )
}

@Composable
private fun PasskeyView(
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
    var isChecking by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

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

                if (message != null) {
                    Text(
                        text = message.orEmpty(),
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
                isLoading = isChecking,
                isEnabled = !isChecking
            ) {
                scope.launch {
                    if (isChecking) return@launch
                    isChecking = true
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
                        message = "Passkey verification is still pending."
                    } catch (error: PasskeySessionExpiredException) {
                        message = "Login session expired."
                    } catch (error: Exception) {
                        message = "Failed to check passkey status: ${error.message}"
                    } finally {
                        isChecking = false
                    }
                }
            }
        }
    )
}

@Composable
private fun PasswordAfterMfaView(
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
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

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
            if (errorMessage != null) {
                Text(
                    text = errorMessage.orEmpty(),
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            }
        },
        bottom = {
            PrimaryButton(
                text = "Continue",
                isLoading = isLoading,
                isEnabled = password.isNotBlank() && !isLoading
            ) {
                scope.launch {
                    if (isLoading) return@launch
                    isLoading = true
                    errorMessage = null
                    try {
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
                    } catch (error: Exception) {
                        errorMessage = "Incorrect password: ${error.message}"
                    } finally {
                        isLoading = false
                    }
                }
            }
        }
    )
}

@Composable
private fun PasskeyPasswordReentryView(
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
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

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
            if (errorMessage != null) {
                Text(
                    text = errorMessage.orEmpty(),
                    style = EnsuTypography.small,
                    color = EnsuColor.error,
                    modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                )
            }
        },
        bottom = {
            PrimaryButton(
                text = "Continue",
                isLoading = isLoading,
                isEnabled = password.isNotBlank() && !isLoading
            ) {
                scope.launch {
                    if (isLoading) return@launch
                    isLoading = true
                    errorMessage = null
                    try {
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
                    } catch (error: Exception) {
                        errorMessage = "Incorrect password: ${error.message}"
                    } finally {
                        isLoading = false
                    }
                }
            }
        }
    )
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
