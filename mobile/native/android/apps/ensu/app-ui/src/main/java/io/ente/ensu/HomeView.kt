@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Menu
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import io.ente.ensu.auth.AuthFlowScreen
import io.ente.ensu.chat.ChatView
import io.ente.ensu.chat.SessionDrawer
import io.ente.ensu.components.ChoiceDialog
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.store.AppStore
import io.ente.ensu.modelsettings.ModelSettingsScreen
import io.ente.ensu.settings.DeveloperSettingsScreen
import io.ente.ensu.settings.LogViewerScreen
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

@Composable
fun HomeView(
    appState: AppState,
    store: AppStore,
    logs: List<LogEntry>,
    authService: EnsuAuthService,
    currentEndpointFlow: Flow<String>
) {
    val drawerState = androidx.compose.material3.rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    var isShowingAuth by remember { mutableStateOf(false) }
    var isShowingSignOutDialog by remember { mutableStateOf(false) }
    var destination by remember { mutableStateOf(HomeDestination.Chat) }

    val currentSession = appState.chat.sessions.firstOrNull { it.id == appState.chat.currentSessionId }
    val currentMessages = appState.chat.messages.filter { it.sessionId == currentSession?.id }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            SessionDrawer(
                sessions = appState.chat.sessions,
                selectedSessionId = appState.chat.currentSessionId,
                isLoggedIn = appState.auth.isLoggedIn,
                userEmail = appState.auth.email,
                onNewChat = {
                    val sessionId = store.createNewSession()
                    store.persistSelectedSession(scope, sessionId)
                    destination = HomeDestination.Chat
                    scope.launch { drawerState.close() }
                },
                onSelectSession = { session ->
                    store.selectSession(session.id)
                    store.persistSelectedSession(scope, session.id)
                    destination = HomeDestination.Chat
                    scope.launch { drawerState.close() }
                },
                onSync = {},
                onOpenLogs = {
                    destination = HomeDestination.Logs
                    scope.launch { drawerState.close() }
                },
                onOpenModelSettings = {
                    destination = HomeDestination.ModelSettings
                    scope.launch { drawerState.close() }
                },
                onOpenDeveloperSettings = {
                    destination = HomeDestination.DeveloperSettings
                    scope.launch { drawerState.close() }
                },
                onSignIn = { isShowingAuth = true },
                onSignOut = { isShowingSignOutDialog = true }
            )
        }
    ) {
        Scaffold(
            containerColor = EnsuColor.backgroundBase(),
            contentWindowInsets = WindowInsets(0, 0, 0, 0),
            topBar = {
                when (destination) {
                    HomeDestination.Chat -> {
                        Column {
                            EnsuTopBar(
                                sessionTitle = currentSession?.title,
                                showBrand = currentMessages.isEmpty(),
                                isLoggedIn = appState.auth.isLoggedIn,
                                onOpenDrawer = { scope.launch { drawerState.open() } },
                                onSignIn = { isShowingAuth = true }
                            )
                            androidx.compose.material3.HorizontalDivider(color = EnsuColor.border())
                        }
                    }
                    HomeDestination.Logs -> {
                        SimpleTopBar(title = "Logs") { destination = HomeDestination.Chat }
                    }
                    HomeDestination.ModelSettings -> {
                        SimpleTopBar(title = "Model Settings") { destination = HomeDestination.Chat }
                    }
                    HomeDestination.DeveloperSettings -> {
                        SimpleTopBar(title = "Developer Settings") { destination = HomeDestination.Chat }
                    }
                }
            }
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                when (destination) {
                    HomeDestination.Chat -> {
                        ChatView(
                            chatState = appState.chat.copy(messages = currentMessages),
                            onMessageChange = store::updateMessageText,
                            onSend = store::sendMessage,
                            onStop = {},
                            onAttachmentSelected = { _: AttachmentType -> },
                            onBranchChange = store::updateBranchSelection
                        )
                    }
                    HomeDestination.Logs -> {
                        LogViewerScreen(logs = logs)
                    }
                    HomeDestination.ModelSettings -> {
                        ModelSettingsScreen()
                    }
                    HomeDestination.DeveloperSettings -> {
                        DeveloperSettingsScreen(
                            authService = authService,
                            currentEndpointFlow = currentEndpointFlow,
                            onSaved = { destination = HomeDestination.Chat }
                        )
                    }
                }
            }
        }
    }

    if (isShowingAuth) {
        AuthFlowScreen(
            authService = authService,
            onLoggedIn = { email ->
                store.signIn(email)
                isShowingAuth = false
            },
            onDismiss = { isShowingAuth = false }
        )
    }

    if (isShowingSignOutDialog) {
        ChoiceDialog(
            title = "Sign Out",
            body = "This will stop syncing your sessions.",
            firstButtonLabel = "Sign Out",
            secondButtonLabel = "Cancel",
            isCritical = false,
            onFirst = {
                authService.clearCredentials()
                store.signOut()
                isShowingSignOutDialog = false
            },
            onSecond = { isShowingSignOutDialog = false },
            onDismiss = { isShowingSignOutDialog = false }
        )
    }
}

@Composable
private fun EnsuTopBar(
    sessionTitle: String?,
    showBrand: Boolean,
    isLoggedIn: Boolean,
    onOpenDrawer: () -> Unit,
    onSignIn: () -> Unit
) {
    val titleText = if (showBrand) "ensu" else sessionTitle?.takeIf { it.isNotBlank() } ?: "New Chat"
    val titleStyle = if (showBrand) EnsuTypography.h3Bold else EnsuTypography.h3Bold

    TopAppBar(
        title = {
            Text(
                text = titleText,
                style = titleStyle,
                color = EnsuColor.textPrimary(),
                maxLines = 1
            )
        },
        navigationIcon = {
            IconButton(onClick = onOpenDrawer) {
                Icon(imageVector = Icons.Outlined.Menu, contentDescription = "Menu")
            }
        },
        actions = {
            if (!isLoggedIn) {
                TextButton(onClick = onSignIn) {
                    Text(text = "Sign In", style = EnsuTypography.small, color = EnsuColor.accent())
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

@Composable
private fun SimpleTopBar(title: String, onBack: () -> Unit) {
    TopAppBar(
        title = { Text(text = title, style = EnsuTypography.h3Bold) },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(imageVector = Icons.Outlined.ArrowBack, contentDescription = "Back")
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

private enum class HomeDestination {
    Chat,
    Logs,
    ModelSettings,
    DeveloperSettings
}

