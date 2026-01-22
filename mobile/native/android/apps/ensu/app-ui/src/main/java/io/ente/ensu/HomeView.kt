@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, androidx.compose.animation.ExperimentalAnimationApi::class)

package io.ente.ensu

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import android.content.Intent
import android.webkit.MimeTypeMap
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.core.tween
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.res.painterResource
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.core.content.FileProvider
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.navigation.NavBackStackEntry
import androidx.navigation.compose.currentBackStackEntryAsState
import com.google.accompanist.navigation.animation.AnimatedNavHost
import com.google.accompanist.navigation.animation.composable
import com.google.accompanist.navigation.animation.rememberAnimatedNavController
import io.ente.ensu.auth.AuthFlowScreen
import io.ente.ensu.chat.ChatView
import io.ente.ensu.chat.SessionDrawer
import io.ente.ensu.components.NativeChoiceDialog
import io.ente.ensu.components.EnsuLogo
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.logging.FileLogRepository
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.HugeIcons
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentDownloadItem
import io.ente.ensu.domain.model.AttachmentDownloadStatus
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.store.AppStore
import io.ente.ensu.modelsettings.ModelSettingsScreen
import io.ente.ensu.settings.DeveloperSettingsScreen
import io.ente.ensu.settings.LogViewerScreen
import io.ente.ensu.settings.SettingsScreen
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

@Composable
fun HomeView(
    appState: AppState,
    store: AppStore,
    logs: List<LogEntry>,
    logRepository: FileLogRepository,
    authService: EnsuAuthService,
    currentEndpointFlow: Flow<String>
) {
    val drawerState = androidx.compose.material3.rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current
    val navController = rememberAnimatedNavController()
    val lifecycleOwner = LocalLifecycleOwner.current
    val latestChatState by rememberUpdatedState(appState.chat)
    val latestStore by rememberUpdatedState(store)
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route ?: HomeRoute.Chat
    val isChatRoute = currentRoute == HomeRoute.Chat
    var isShowingAuth by remember { mutableStateOf(false) }
    var isShowingSignOutDialog by remember { mutableStateOf(false) }
    var showAttachmentDownloads by remember { mutableStateOf(false) }
    var deleteSessionTarget by remember { mutableStateOf<io.ente.ensu.domain.model.ChatSession?>(null) }
    var showLogShareDialog by remember { mutableStateOf(false) }

    var developerTapCount by remember { mutableStateOf(0) }
    var lastDeveloperTapAt by remember { mutableStateOf<Long?>(null) }
    var showDeveloperDialog by remember { mutableStateOf(false) }

    val handleDeveloperTap: () -> Unit = handle@{
        // Don't allow switching endpoints for logged-in users.
        if (appState.auth.isLoggedIn) return@handle

        val now = System.currentTimeMillis()
        val last = lastDeveloperTapAt
        if (last != null && now - last > 2000) {
            developerTapCount = 0
        }
        lastDeveloperTapAt = now
        developerTapCount += 1
        if (developerTapCount >= 5) {
            developerTapCount = 0
            showDeveloperDialog = true
        }
    }

    val imagePicker = androidx.activity.compose.rememberLauncherForActivityResult(
        contract = androidx.activity.result.contract.ActivityResultContracts.GetContent()
    ) { uri ->
        if (uri != null) {
            store.setAttachmentProcessing(true)
            scope.launch {
                val attachment = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                    buildAttachmentFromUri(context, uri, io.ente.ensu.domain.model.AttachmentType.Image)
                }
                if (attachment != null) {
                    store.addAttachment(attachment)
                } else {
                    store.setAttachmentProcessing(false)
                }
            }
        }
    }

    val documentPicker = androidx.activity.compose.rememberLauncherForActivityResult(
        contract = androidx.activity.result.contract.ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri != null) {
            store.setAttachmentProcessing(true)
            scope.launch {
                val attachment = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                    buildAttachmentFromUri(context, uri, io.ente.ensu.domain.model.AttachmentType.Document)
                }
                if (attachment != null) {
                    store.addAttachment(attachment)
                } else {
                    store.setAttachmentProcessing(false)
                }
            }
        }
    }

    val exportLogsLauncher = androidx.activity.compose.rememberLauncherForActivityResult(
        contract = androidx.activity.result.contract.ActivityResultContracts.CreateDocument("application/zip")
    ) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            try {
                val zipFile = logRepository.createLogsZip()
                context.contentResolver.openOutputStream(uri)?.use { out ->
                    zipFile.inputStream().use { input -> input.copyTo(out) }
                }
                Toast.makeText(context, "Logs exported", Toast.LENGTH_SHORT).show()
            } catch (err: Throwable) {
                Toast.makeText(context, "Export failed: ${err.message ?: "Unknown error"}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    val shareLogs: () -> Unit = {
        scope.launch {
            try {
                val zipFile = logRepository.createLogsZip()
                val uri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    zipFile
                )
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "application/zip"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                context.startActivity(Intent.createChooser(intent, "Share logs"))
            } catch (err: Throwable) {
                Toast.makeText(context, "Share failed: ${err.message ?: "Unknown error"}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    val exportLogs: () -> Unit = {
        val name = "ensu-logs-${System.currentTimeMillis()}.zip"
        exportLogsLauncher.launch(name)
    }

    val currentSession = appState.chat.sessions.firstOrNull { it.id == appState.chat.currentSessionId }

    BackHandler(enabled = isShowingAuth) {
        isShowingAuth = false
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                val chatState = latestChatState
                if (
                    chatState.hasRequestedModelDownload &&
                    !chatState.isModelDownloaded &&
                    !chatState.isDownloading &&
                    !chatState.isGenerating
                ) {
                    latestStore.startModelDownload(userInitiated = false)
                }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    androidx.compose.runtime.LaunchedEffect(currentRoute) {
        if (!isChatRoute) {
            drawerState.close()
        }
    }

    val scaffoldContent: @Composable () -> Unit = {
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
                                isLoggedIn = appState.auth.isLoggedIn,
                                attachmentDownloads = appState.chat.attachmentDownloads,
                                attachmentDownloadProgress = appState.chat.attachmentDownloadProgress,
                                modelDownloadStatus = appState.chat.downloadStatus,
                                modelDownloadPercent = appState.chat.downloadPercent,
                                onOpenDrawer = { scope.launch { drawerState.open() } },
                                onSignIn = { isShowingAuth = true },
                                onAttachmentDownloads = { showAttachmentDownloads = true }
                            )
                            androidx.compose.material3.HorizontalDivider(color = EnsuColor.border())
                        }
                    }
                    HomeRoute.Logs -> {
                        LogsTopBar(
                            onBack = { navController.popBackStack() },
                            onShare = { showLogShareDialog = true }
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
                            onMessageChange = store::updateMessageText,
                            onSend = store::sendMessage,
                            onStop = store::stopGeneration,
                            onCancelDownload = store::cancelDownload,
                            onAttachmentSelected = { type ->
                                when (type) {
                                    io.ente.ensu.domain.model.AttachmentType.Image -> {
                                        imagePicker.launch("image/*")
                                    }
                                    io.ente.ensu.domain.model.AttachmentType.Document -> {
                                        documentPicker.launch(arrayOf("*/*"))
                                    }
                                }
                            },
                            onRemoveAttachment = store::removeAttachment,
                            onEditMessage = { message -> store.beginEditing(message.id) },
                            onRetryMessage = { message -> store.retryAssistantMessage(message.id) },
                            onCancelEdit = store::cancelEditing,
                            onBranchChange = store::updateBranchSelection,
                            onOpenAttachment = { attachment ->
                                openAttachment(context, attachment)
                            },
                            onStartDownload = { store.startModelDownload(userInitiated = true) }
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
                            onOpenModelSettings = { navController.navigate(HomeRoute.ModelSettings) },
                            onOpenLogs = { navController.navigate(HomeRoute.Logs) }
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
                            onSaved = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        gesturesEnabled = isChatRoute,
        drawerContent = {
            if (isChatRoute) {
                SessionDrawer(
                    sessions = appState.chat.sessions,
                    selectedSessionId = appState.chat.currentSessionId,
                    isLoggedIn = appState.auth.isLoggedIn,
                    userEmail = appState.auth.email,
                    onNewChat = {
                        // We're already on the chat route when the drawer is visible.
                        // Avoid re-navigating to the same destination, which causes an unnecessary transition.
                        store.startNewSessionDraft()
                        store.persistSelectedSession(scope, null)
                        scope.launch { drawerState.close() }
                    },
                    onSelectSession = { session ->
                        // Same reason as above: just swap the session in-place.
                        store.selectSession(session.id)
                        store.persistSelectedSession(scope, session.id)
                        scope.launch { drawerState.close() }
                    },
                    onDeleteSession = { session ->
                        deleteSessionTarget = session
                    },
                    onSync = {
                        store.syncNow { message ->
                            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                        }
                    },
                    onOpenSettings = {
                        navController.navigate(HomeRoute.Settings)
                        scope.launch { drawerState.close() }
                    },
                    onDeveloperTap = {
                        handleDeveloperTap()
                    },
                    onSignIn = { isShowingAuth = true },
                    onSignOut = { isShowingSignOutDialog = true }
                )
            } else {
                Box(modifier = Modifier.width(1.dp))
            }
        }
    ) {
        scaffoldContent()
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

    if (showAttachmentDownloads) {
        AttachmentDownloadsDialog(
            downloads = appState.chat.attachmentDownloads,
            onCancel = { store.cancelAttachmentDownload(it) },
            onDismiss = { showAttachmentDownloads = false }
        )
    }

    if (deleteSessionTarget != null) {
        NativeChoiceDialog(
            title = "Delete Chat",
            body = "This will delete the chat and sync the change.",
            firstButtonLabel = "Delete",
            secondButtonLabel = "Cancel",
            onFirst = {
                deleteSessionTarget?.let { session ->
                    store.deleteSession(session.id)
                    store.persistSelectedSession(scope, appState.chat.currentSessionId)
                }
                deleteSessionTarget = null
            },
            onSecond = { deleteSessionTarget = null },
            onDismiss = { deleteSessionTarget = null }
        )
    }

    if (showLogShareDialog) {
        ModalBottomSheet(
            onDismissRequest = { showLogShareDialog = false },
            containerColor = EnsuColor.backgroundBase()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = EnsuSpacing.lg.dp, vertical = EnsuSpacing.md.dp),
                verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)
            ) {
                Text(text = "Logs", style = EnsuTypography.h3Bold, color = EnsuColor.textPrimary())
                Text(text = "Export or share logs for support.", style = EnsuTypography.body, color = EnsuColor.textMuted())
                Row(horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)) {
                    TextButton(onClick = {
                        showLogShareDialog = false
                        shareLogs()
                    }) {
                        Text(text = "Share")
                    }
                    TextButton(onClick = {
                        showLogShareDialog = false
                        exportLogs()
                    }) {
                        Text(text = "Export")
                    }
                    Spacer(modifier = Modifier.weight(1f))
                    TextButton(onClick = { showLogShareDialog = false }) {
                        Text(text = "Cancel")
                    }
                }
                Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))
            }
        }
    }

    if (showDeveloperDialog) {
        AlertDialog(
            onDismissRequest = { showDeveloperDialog = false },
            title = {
                Text(text = "Developer settings", style = EnsuTypography.h3Bold)
            },
            text = {
                Text(
                    text = "Are you sure that you want to modify Developer settings?",
                    style = EnsuTypography.body,
                    color = EnsuColor.textMuted()
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeveloperDialog = false
                        navController.navigate(HomeRoute.DeveloperSettings)
                        scope.launch { drawerState.close() }
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.accent())
                ) {
                    Text(text = "Yes")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showDeveloperDialog = false },
                    colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textMuted())
                ) {
                    Text(text = "Cancel")
                }
            },
            containerColor = EnsuColor.backgroundBase()
        )
    }

    if (isShowingSignOutDialog) {
        NativeChoiceDialog(
            title = "Sign Out",
            body = "This will stop syncing your sessions.",
            firstButtonLabel = "Sign Out",
            secondButtonLabel = "Cancel",
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
    attachmentDownloads: List<io.ente.ensu.domain.model.AttachmentDownloadItem>,
    attachmentDownloadProgress: Int?,
    modelDownloadStatus: String?,
    modelDownloadPercent: Int?,
    onOpenDrawer: () -> Unit,
    onSignIn: () -> Unit,
    onAttachmentDownloads: () -> Unit
) {
    val titleText = sessionTitle?.takeIf { it.isNotBlank() } ?: "New Chat"

    CenterAlignedTopAppBar(
        title = {
            if (showBrand) {
                EnsuLogo(height = 20.dp)
            } else {
                Text(
                    text = titleText,
                    style = EnsuTypography.h3Bold.copy(fontSize = 20.sp, lineHeight = 24.sp),
                    color = EnsuColor.textPrimary(),
                    maxLines = 1
                )
            }
        },
        navigationIcon = {
            IconButton(onClick = onOpenDrawer) {
                Icon(
                    painter = painterResource(HugeIcons.Menu01Icon),
                    contentDescription = "Menu"
                )
            }
        },
        actions = {
            val isLoading = modelDownloadStatus?.contains("Loading", ignoreCase = true) == true
            val showModelProgress = isLoading

            if (!isLoggedIn) {
                if (showModelProgress) {
                    ModelProgressIndicator(
                        isLoading = isLoading,
                        progressPercent = modelDownloadPercent
                    )
                    Spacer(modifier = Modifier.width(EnsuSpacing.md.dp))
                }
                TextButton(onClick = onSignIn) {
                    Text(text = "Sign In", style = EnsuTypography.small, color = EnsuColor.accent())
                }
            } else {
                val hasPending = attachmentDownloads.any {
                    it.status == AttachmentDownloadStatus.Queued ||
                        it.status == AttachmentDownloadStatus.Downloading ||
                        it.status == AttachmentDownloadStatus.Failed
                }
                if (hasPending) {
                    val active = attachmentDownloads.filter { it.status != AttachmentDownloadStatus.Canceled }
                    val completed = active.count { it.status == AttachmentDownloadStatus.Completed }
                    val total = active.size
                    TextButton(
                        onClick = onAttachmentDownloads,
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                painter = painterResource(HugeIcons.Upload01Icon),
                                contentDescription = "Attachment downloads",
                                tint = EnsuColor.textPrimary()
                            )
                            Text(
                                text = "$completed/$total",
                                style = EnsuTypography.mini,
                                color = EnsuColor.textMuted(),
                                maxLines = 1,
                                softWrap = false,
                                modifier = Modifier.padding(start = 6.dp)
                            )
                        }
                    }
                }
                if (showModelProgress) {
                    if (hasPending) {
                        Spacer(modifier = Modifier.width(EnsuSpacing.md.dp))
                    }
                    ModelProgressIndicator(
                        isLoading = isLoading,
                        progressPercent = modelDownloadPercent,
                        modifier = Modifier.padding(end = EnsuSpacing.sm.dp)
                    )
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

@Composable
private fun ModelProgressIndicator(
    isLoading: Boolean,
    progressPercent: Int?,
    modifier: Modifier = Modifier
) {
    val indicatorModifier = modifier.size(16.dp)
    val clamped = progressPercent?.coerceIn(0, 100)
    if (!isLoading && clamped != null) {
        CircularProgressIndicator(
            progress = { clamped / 100f },
            modifier = indicatorModifier,
            color = EnsuColor.accent(),
            trackColor = EnsuColor.border(),
            strokeWidth = 2.dp
        )
    } else {
        CircularProgressIndicator(
            modifier = indicatorModifier,
            color = EnsuColor.accent(),
            trackColor = EnsuColor.border(),
            strokeWidth = 2.dp
        )
    }
}

@Composable
private fun AttachmentDownloadsDialog(
    downloads: List<AttachmentDownloadItem>,
    onCancel: (String) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(text = "Attachment downloads", style = EnsuTypography.h3Bold) },
        text = {
            if (downloads.isEmpty()) {
                Text(text = "No pending downloads", style = EnsuTypography.body, color = EnsuColor.textMuted())
            } else {
                Column(
                    modifier = Modifier
                        .heightIn(max = 320.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    downloads.forEach { item ->
                        Row(
                            modifier = Modifier.padding(vertical = EnsuSpacing.xs.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(text = item.name, style = EnsuTypography.body, color = EnsuColor.textPrimary())
                                Text(
                                    text = "Session ${item.sessionId.take(6)} • ${item.sizeBytes / 1024} KB",
                                    style = EnsuTypography.mini,
                                    color = EnsuColor.textMuted()
                                )
                            }
                            Text(
                                text = statusLabel(item.status),
                                style = EnsuTypography.mini,
                                color = EnsuColor.textMuted(),
                                modifier = Modifier.padding(end = EnsuSpacing.xs.dp)
                            )
                            if (item.status == AttachmentDownloadStatus.Queued || item.status == AttachmentDownloadStatus.Downloading) {
                                TextButton(onClick = { onCancel(item.id) }) {
                                    Text(text = "Cancel", style = EnsuTypography.mini)
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(text = "Close", style = EnsuTypography.small)
            }
        }
    )
}

private fun statusLabel(status: AttachmentDownloadStatus): String {
    return when (status) {
        AttachmentDownloadStatus.Queued -> "Queued"
        AttachmentDownloadStatus.Downloading -> "Downloading"
        AttachmentDownloadStatus.Completed -> "Completed"
        AttachmentDownloadStatus.Failed -> "Failed"
        AttachmentDownloadStatus.Canceled -> "Canceled"
    }
}

@Composable
private fun SimpleTopBar(title: String, onBack: () -> Unit) {
    TopAppBar(
        title = { Text(text = title, style = EnsuTypography.h3Bold.copy(fontSize = 20.sp, lineHeight = 24.sp)) },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(
                    painter = painterResource(HugeIcons.ArrowLeft01Icon),
                    contentDescription = "Back"
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

private object HomeRoute {
    const val Chat = "chat"
    const val Settings = "settings"
    const val Logs = "logs"
    const val ModelSettings = "model-settings"
    const val DeveloperSettings = "developer-settings"
}

@Composable
private fun LogsTopBar(onBack: () -> Unit, onShare: () -> Unit) {
    TopAppBar(
        title = { Text(text = "Logs", style = EnsuTypography.h3Bold.copy(fontSize = 20.sp, lineHeight = 24.sp)) },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(
                    painter = painterResource(HugeIcons.ArrowLeft01Icon),
                    contentDescription = "Back"
                )
            }
        },
        actions = {
            IconButton(onClick = onShare) {
                Icon(
                    painter = painterResource(HugeIcons.Upload01Icon),
                    contentDescription = "Share"
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

private fun androidx.compose.animation.AnimatedContentTransitionScope<NavBackStackEntry>.forwardEnter() =
    slideInHorizontally(
        initialOffsetX = { it },
        animationSpec = tween(220)
    ) + fadeIn(animationSpec = tween(90))

private fun androidx.compose.animation.AnimatedContentTransitionScope<NavBackStackEntry>.forwardExit() =
    slideOutHorizontally(
        targetOffsetX = { -it },
        animationSpec = tween(220)
    ) + fadeOut(animationSpec = tween(90))

private fun androidx.compose.animation.AnimatedContentTransitionScope<NavBackStackEntry>.backEnter() =
    slideInHorizontally(
        initialOffsetX = { -it },
        animationSpec = tween(220)
    ) + fadeIn(animationSpec = tween(90))

private fun androidx.compose.animation.AnimatedContentTransitionScope<NavBackStackEntry>.backExit() =
    slideOutHorizontally(
        targetOffsetX = { it },
        animationSpec = tween(220)
    ) + fadeOut(animationSpec = tween(90))

private fun buildAttachmentFromUri(
    context: Context,
    uri: Uri,
    type: AttachmentType
): Attachment? {
    val resolver = context.contentResolver
    val name = queryDisplayName(resolver, uri)
    val size = querySize(resolver, uri)
    val rawName = name ?: when (type) {
        AttachmentType.Image -> "image"
        AttachmentType.Document -> "document"
    }
    val safeName = rawName.replace("/", "_")

    val attachmentsDir = File(context.filesDir, "attachments")
    if (!attachmentsDir.exists()) {
        attachmentsDir.mkdirs()
    }

    val attachmentId = UUID.randomUUID().toString()
    val destination = File(attachmentsDir, attachmentId)
    return runCatching {
        val inputStream = resolver.openInputStream(uri) ?: return@runCatching null

        inputStream.use { input ->
            FileOutputStream(destination).use { output ->
                input.copyTo(output)
            }
        }

        val finalSize = destination.length().takeIf { it > 0 } ?: size ?: 0L

        Attachment(
            id = attachmentId,
            name = name ?: safeName,
            sizeBytes = finalSize,
            type = type,
            localPath = destination.absolutePath,
            isUploading = false
        )
    }.getOrNull()
}

private fun openAttachment(context: Context, attachment: Attachment) {
    val path = attachment.localPath
    if (path.isNullOrBlank()) {
        Toast.makeText(context, "Attachment not available", Toast.LENGTH_SHORT).show()
        return
    }
    val file = File(path)
    if (!file.exists()) {
        Toast.makeText(context, "Attachment not downloaded", Toast.LENGTH_SHORT).show()
        return
    }

    val extension = file.extension.lowercase()
    val mimeFromExtension = if (extension.isNotBlank()) {
        MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
    } else {
        null
    }
    val mime = when {
        attachment.type == AttachmentType.Image -> mimeFromExtension ?: "image/*"
        else -> mimeFromExtension ?: "*/*"
    }

    val uri = FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
    val intent = Intent(Intent.ACTION_VIEW)
        .setDataAndType(uri, mime)
        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    val chooser = Intent.createChooser(intent, "Open attachment")
    val resolved = intent.resolveActivity(context.packageManager)
    if (resolved != null) {
        context.startActivity(chooser)
    } else {
        Toast.makeText(context, "No app available to open this file", Toast.LENGTH_SHORT).show()
    }
}

private fun queryDisplayName(resolver: android.content.ContentResolver, uri: Uri): String? {
    resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0) return cursor.getString(index)
        }
    }
    return null
}

private fun querySize(resolver: android.content.ContentResolver, uri: Uri): Long? {
    resolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)?.use { cursor ->
        if (cursor.moveToFirst()) {
            val index = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (index >= 0) return cursor.getLong(index)
        }
    }
    return null
}

