@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu.auth

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import io.ente.ensu.components.EnsuLogo
import io.ente.ensu.data.auth.AuthResponsePayload
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.auth.KeyAttributes
import io.ente.ensu.data.auth.SrpAttributes
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.HugeIcons

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
                    EnsuLogo(height = 20.dp)
                },
                navigationIcon = {
                    IconButton(onClick = {
                        if (canGoBack) {
                            backStack.removeLast()
                        } else {
                            onDismiss()
                        }
                    }) {
                        Icon(
                            painter = painterResource(HugeIcons.ArrowLeft01Icon),
                            contentDescription = "Back"
                        )
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
