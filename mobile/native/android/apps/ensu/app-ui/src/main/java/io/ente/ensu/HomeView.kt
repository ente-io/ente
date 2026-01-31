@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, androidx.compose.animation.ExperimentalAnimationApi::class)

package io.ente.ensu

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.navigation.compose.currentBackStackEntryAsState
import com.google.accompanist.navigation.animation.rememberAnimatedNavController
import io.ente.ensu.auth.AuthFlowScreen
import io.ente.ensu.chat.SessionDrawer
import io.ente.ensu.components.NativeChoiceDialog
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.logging.FileLogRepository
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.store.AppStore
import io.ente.ensu.utils.EnsuFeatureFlags
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
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
    var showSignInComingSoon by remember { mutableStateOf(false) }

    var developerTapCount by remember { mutableStateOf(0) }
    var lastDeveloperTapAt by remember { mutableStateOf<Long?>(null) }
    var showDeveloperDialog by remember { mutableStateOf(false) }

    val handleSignInRequest: () -> Unit = {
        if (EnsuFeatureFlags.enableSignIn) {
            isShowingAuth = true
        } else {
            showSignInComingSoon = true
        }
    }

    val handleDeveloperTap: () -> Unit = handle@{
        if (!EnsuFeatureFlags.enableSignIn) return@handle
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

    val imagePicker = rememberAttachmentPicker(
        contract = ActivityResultContracts.GetContent(),
        type = AttachmentType.Image,
        store = store,
        context = context
    )

    val documentPicker = rememberAttachmentPicker(
        contract = ActivityResultContracts.OpenDocument(),
        type = AttachmentType.Document,
        store = store,
        context = context
    )

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

    val currentSession by remember(appState.chat.sessions, appState.chat.currentSessionId) {
        derivedStateOf {
            appState.chat.sessions.firstOrNull { it.id == appState.chat.currentSessionId }
        }
    }

    BackHandler(enabled = isShowingAuth) {
        isShowingAuth = false
    }

    BackHandler(enabled = !isChatRoute) {
        if (!navController.popBackStack()) {
            navController.navigate(HomeRoute.Chat) { launchSingleTop = true }
        }
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

    // Note: Drawer close is handled in navigation callbacks (onOpenSettings, onAccount, etc.)
    // to avoid race conditions with route changes during navigation transitions.

    val openDrawer: () -> Unit = { scope.launch { drawerState.open() } }

    val handleAttachmentSelected: (AttachmentType) -> Unit = { type ->
        when (type) {
            AttachmentType.Image -> {
                imagePicker.launch("image/*")
            }
            AttachmentType.Document -> {
                documentPicker.launch(arrayOf("*/*"))
            }
        }
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        gesturesEnabled = isChatRoute,
        drawerContent = {
            // Always render SessionDrawer - don't conditionally swap content based on route.
            // Changing drawer content while navigating can cause race conditions with the
            // navigation back stack. The drawer is already hidden via gesturesEnabled.
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
                    store.syncNow(
                        onSuccess = {
                            Toast.makeText(context, "Sync complete", Toast.LENGTH_SHORT).show()
                        },
                        onError = { message ->
                            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                        }
                    )
                },
                onOpenSettings = {
                    navController.navigate(HomeRoute.Settings) {
                        launchSingleTop = true
                        restoreState = true
                        popUpTo(HomeRoute.Chat) { inclusive = false }
                    }
                    scope.launch { drawerState.close() }
                },
                onDeveloperTap = {
                    handleDeveloperTap()
                }
            )
        }
    ) {
        HomeNavigation(
            appState = appState,
            store = store,
            logRepository = logRepository,
            authService = authService,
            currentEndpointFlow = currentEndpointFlow,
            navController = navController,
            drawerState = drawerState,
            currentRoute = currentRoute,
            currentSession = currentSession,
            onSignIn = handleSignInRequest,
            onSignOut = { isShowingSignOutDialog = true },
            onOpenDrawer = openDrawer,
            onAttachmentDownloads = { showAttachmentDownloads = true },
            onShowLogShareDialog = { showLogShareDialog = true },
            onAttachmentSelected = handleAttachmentSelected,
            onOpenAttachment = { attachment -> openAttachment(context, attachment) },
            onDeleteAccount = { openDeleteAccountEmail(context) }
        )
    }

    AnimatedVisibility(
        visible = isShowingAuth,
        enter = slideInHorizontally(
            initialOffsetX = { fullWidth -> fullWidth },
            animationSpec = tween(220)
        ) + fadeIn(animationSpec = tween(90)),
        exit = slideOutHorizontally(
            targetOffsetX = { fullWidth -> fullWidth },
            animationSpec = tween(220)
        ) + fadeOut(animationSpec = tween(90))
    ) {
        AuthFlowScreen(
            authService = authService,
            onLoggedIn = { email ->
                store.signIn(email)
                isShowingAuth = false
            },
            onDismiss = { isShowingAuth = false }
        )
    }

    if (showSignInComingSoon) {
        ComingSoonDialog(
            title = "Sign in",
            message = "Coming soon",
            onDismiss = { showSignInComingSoon = false }
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
                    TextButton(
                        onClick = {
                            showLogShareDialog = false
                            shareLogs()
                        },
                        colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textPrimary())
                    ) {
                        Text(text = "Share")
                    }
                    TextButton(
                        onClick = {
                            showLogShareDialog = false
                            exportLogs()
                        },
                        colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textPrimary())
                    ) {
                        Text(text = "Export")
                    }
                    Spacer(modifier = Modifier.weight(1f))
                    TextButton(
                        onClick = { showLogShareDialog = false },
                        colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textMuted())
                    ) {
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
                        navController.navigate(HomeRoute.DeveloperSettings) {
                            launchSingleTop = true
                            restoreState = true
                            popUpTo(HomeRoute.Chat) { inclusive = false }
                        }
                        scope.launch { drawerState.close() }
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textPrimary())
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
private fun <I> rememberAttachmentPicker(
    contract: ActivityResultContract<I, Uri?>,
    type: AttachmentType,
    store: AppStore,
    context: Context
): ManagedActivityResultLauncher<I, Uri?> {
    val scope = rememberCoroutineScope()
    val latestStore by rememberUpdatedState(store)

    return rememberLauncherForActivityResult(contract = contract) { uri ->
        if (uri != null) {
            latestStore.setAttachmentProcessing(true)
            scope.launch {
                val attachment = withContext(Dispatchers.IO) {
                    buildAttachmentFromUri(context, uri, type)
                }
                if (attachment != null) {
                    latestStore.addAttachment(attachment)
                } else {
                    latestStore.setAttachmentProcessing(false)
                }
            }
        }
    }
}

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

private fun openDeleteAccountEmail(context: Context) {
    val subject = Uri.encode("Request Deletion for Ente Account")
    val uri = Uri.parse("mailto:support@ente.io?subject=$subject")
    val intent = Intent(Intent.ACTION_SENDTO, uri)
    val resolved = intent.resolveActivity(context.packageManager)
    if (resolved != null) {
        context.startActivity(intent)
    } else {
        Toast.makeText(context, "No email app available", Toast.LENGTH_SHORT).show()
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

