@file:OptIn(ExperimentalAnimationApi::class)

package io.ente.ensu

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.ExperimentalAnimationApi
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DrawerState
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavBackStackEntry
import androidx.navigation.NavHostController
import com.google.accompanist.navigation.animation.AnimatedNavHost
import com.google.accompanist.navigation.animation.composable
import io.ente.ensu.chat.ChatView
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.store.AppStore
import io.ente.ensu.modelsettings.ModelSettingsScreen
import io.ente.ensu.settings.DeveloperSettingsScreen
import io.ente.ensu.settings.LogViewerScreen
import io.ente.ensu.settings.SettingsScreen
import kotlinx.coroutines.flow.Flow

@Composable
internal fun HomeNavigation(
    appState: AppState,
    store: AppStore,
    logRepository: io.ente.ensu.data.logging.FileLogRepository,
    authService: io.ente.ensu.data.auth.EnsuAuthService,
    currentEndpointFlow: Flow<String>,
    navController: NavHostController,
    drawerState: DrawerState,
    currentRoute: String,
    currentSession: io.ente.ensu.domain.model.ChatSession?,
    onSignIn: () -> Unit,
    onSignOut: () -> Unit,
    onOpenDrawer: () -> Unit,
    onNewChat: () -> Unit,
    onAttachmentDownloads: () -> Unit,
    onShowLogShareDialog: () -> Unit,
    onAttachmentSelected: (AttachmentType) -> Unit,
    onOpenAttachment: (Attachment) -> Unit,
    onDeleteAccount: () -> Unit
) {
    Scaffold(
        containerColor = EnsuColor.backgroundBase(),
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            when (currentRoute) {
                HomeRoute.Chat -> {
                    Column {
                        EnsuTopBar(
                            sessionTitle = currentSession?.title,
                            showBrand = appState.chat.messages.isEmpty(),
                            attachmentDownloads = appState.chat.attachmentDownloads,
                            attachmentDownloadProgress = appState.chat.attachmentDownloadProgress,
                            modelDownloadStatus = appState.chat.downloadStatus,
                            modelDownloadPercent = appState.chat.downloadPercent,
                            onOpenDrawer = onOpenDrawer,
                            onNewChat = onNewChat,
                            onAttachmentDownloads = onAttachmentDownloads
                        )
                        androidx.compose.material3.HorizontalDivider(color = EnsuColor.border())
                    }
                }
                HomeRoute.Logs -> {
                    LogsTopBar(
                        onBack = { navController.popBackStack() },
                        onShare = onShowLogShareDialog
                    )
                }
                HomeRoute.ModelSettings -> {
                    SimpleTopBar(title = "Model Settings") { navController.popBackStack() }
                }
                HomeRoute.DeveloperSettings -> {
                    SimpleTopBar(title = "Developer Settings") { navController.popBackStack() }
                }
                HomeRoute.Settings -> {
                    SimpleTopBar(title = "Settings") { navController.popBackStack() }
                }
                else -> Unit
            }
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            AnimatedNavHost(
                navController = navController,
                startDestination = HomeRoute.Chat,
                modifier = Modifier.fillMaxSize()
            ) {
                composable(
                    route = HomeRoute.Chat,
                    enterTransition = { forwardEnter() },
                    exitTransition = { forwardExit() },
                    popEnterTransition = { backEnter() },
                    popExitTransition = { backExit() }
                ) {
                    ChatView(
                        chatState = appState.chat,
                        isDrawerOpen = drawerState.currentValue == DrawerValue.Open,
                        onMessageChange = store::updateMessageText,
                        onSend = store::sendMessage,
                        onStop = store::stopGeneration,
                        onCancelDownload = store::cancelDownload,
                        onAttachmentSelected = onAttachmentSelected,
                        onRemoveAttachment = store::removeAttachment,
                        onEditMessage = { message -> store.beginEditing(message.id) },
                        onRetryMessage = { message -> store.retryAssistantMessage(message.id) },
                        onCancelEdit = store::cancelEditing,
                        onBranchChange = store::updateBranchSelection,
                        onOpenAttachment = onOpenAttachment,
                        onStartDownload = { userInitiated ->
                            store.startModelDownload(userInitiated = userInitiated)
                        },
                        onOverflowTrim = store::confirmOverflowTrim,
                        onOverflowIncreaseContext = {
                            store.cancelOverflowDialog()
                            navController.navigate(HomeRoute.ModelSettings)
                        },
                        onOverflowCancel = store::cancelOverflowDialog
                    )
                }
                composable(
                    route = HomeRoute.Settings,
                    enterTransition = { forwardEnter() },
                    exitTransition = { forwardExit() },
                    popEnterTransition = { backEnter() },
                    popExitTransition = { backExit() }
                ) {
                    val currentEndpoint by currentEndpointFlow.collectAsState(initial = "https://api.ente.io")
                    SettingsScreen(
                        currentEndpoint = currentEndpoint,
                        isLoggedIn = appState.auth.isLoggedIn,
                        userEmail = appState.auth.email,
                        onOpenLogs = { navController.navigate(HomeRoute.Logs) },
                        onSignOut = onSignOut,
                        onSignIn = onSignIn,
                        onDeleteAccount = onDeleteAccount
                    )
                }
                composable(
                    route = HomeRoute.Logs,
                    enterTransition = { forwardEnter() },
                    exitTransition = { forwardExit() },
                    popEnterTransition = { backEnter() },
                    popExitTransition = { backExit() }
                ) {
                    LogViewerScreen(
                        logRepository = logRepository
                    )
                }
                composable(
                    route = HomeRoute.ModelSettings,
                    enterTransition = { forwardEnter() },
                    exitTransition = { forwardExit() },
                    popEnterTransition = { backEnter() },
                    popExitTransition = { backExit() }
                ) {
                    ModelSettingsScreen(
                        state = appState.modelSettings,
                        onSave = store::updateModelSettings,
                        onReset = store::resetModelSettings
                    )
                }
                composable(
                    route = HomeRoute.DeveloperSettings,
                    enterTransition = { forwardEnter() },
                    exitTransition = { forwardExit() },
                    popEnterTransition = { backEnter() },
                    popExitTransition = { backExit() }
                ) {
                    DeveloperSettingsScreen(
                        authService = authService,
                        currentEndpointFlow = currentEndpointFlow,
                        onOpenModelSettings = { navController.navigate(HomeRoute.ModelSettings) },
                        onSaved = { navController.popBackStack() }
                    )
                }
            }
        }
    }
}

internal object HomeRoute {
    const val Chat = "chat"
    const val Settings = "settings"
    const val Logs = "logs"
    const val ModelSettings = "model-settings"
    const val DeveloperSettings = "developer-settings"
}

internal fun AnimatedContentTransitionScope<NavBackStackEntry>.forwardEnter() =
    slideInHorizontally(
        initialOffsetX = { it },
        animationSpec = tween(220)
    ) + fadeIn(animationSpec = tween(90))

internal fun AnimatedContentTransitionScope<NavBackStackEntry>.forwardExit() =
    slideOutHorizontally(
        targetOffsetX = { -it },
        animationSpec = tween(220)
    ) + fadeOut(animationSpec = tween(90))

internal fun AnimatedContentTransitionScope<NavBackStackEntry>.backEnter() =
    slideInHorizontally(
        initialOffsetX = { -it },
        animationSpec = tween(220)
    ) + fadeIn(animationSpec = tween(90))

internal fun AnimatedContentTransitionScope<NavBackStackEntry>.backExit() =
    slideOutHorizontally(
        targetOffsetX = { it },
        animationSpec = tween(220)
    ) + fadeOut(animationSpec = tween(90))
