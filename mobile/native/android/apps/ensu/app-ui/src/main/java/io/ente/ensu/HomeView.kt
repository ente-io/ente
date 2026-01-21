@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import android.content.Intent
import android.webkit.MimeTypeMap
import android.widget.Toast
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Menu
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.core.content.FileProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.ente.ensu.auth.AuthFlowScreen
import io.ente.ensu.chat.ChatView
import io.ente.ensu.chat.SessionDrawer
import io.ente.ensu.components.ChoiceDialog
import io.ente.ensu.components.EnsuLogo
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.designsystem.EnsuColor
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
    authService: EnsuAuthService,
    currentEndpointFlow: Flow<String>
) {
    val drawerState = androidx.compose.material3.rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current
    var isShowingAuth by remember { mutableStateOf(false) }
    var isShowingSignOutDialog by remember { mutableStateOf(false) }
    var destination by remember { mutableStateOf(HomeDestination.Chat) }
    var showAttachmentDownloads by remember { mutableStateOf(false) }
    var deleteSessionTarget by remember { mutableStateOf<io.ente.ensu.domain.model.ChatSession?>(null) }

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

    val currentSession = appState.chat.sessions.firstOrNull { it.id == appState.chat.currentSessionId }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            SessionDrawer(
                sessions = appState.chat.sessions,
                selectedSessionId = appState.chat.currentSessionId,
                isLoggedIn = appState.auth.isLoggedIn,
                userEmail = appState.auth.email,
                onNewChat = {
                    store.startNewSessionDraft()
                    store.persistSelectedSession(scope, null)
                    destination = HomeDestination.Chat
                    scope.launch { drawerState.close() }
                },
                onSelectSession = { session ->
                    store.selectSession(session.id)
                    store.persistSelectedSession(scope, session.id)
                    destination = HomeDestination.Chat
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
                                showBrand = appState.chat.messages.isEmpty(),
                                isLoggedIn = appState.auth.isLoggedIn,
                                attachmentDownloads = appState.chat.attachmentDownloads,
                                attachmentDownloadProgress = appState.chat.attachmentDownloadProgress,
                                onOpenDrawer = { scope.launch { drawerState.open() } },
                                onSignIn = { isShowingAuth = true },
                                onAttachmentDownloads = { showAttachmentDownloads = true }
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
                            }
                        )
                    }
                    HomeDestination.Logs -> {
                        LogViewerScreen(logs = logs)
                    }
                    HomeDestination.ModelSettings -> {
                        ModelSettingsScreen(
                            state = appState.modelSettings,
                            onSave = store::updateModelSettings,
                            onReset = store::resetModelSettings
                        )
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

    if (showAttachmentDownloads) {
        AttachmentDownloadsDialog(
            downloads = appState.chat.attachmentDownloads,
            onCancel = { store.cancelAttachmentDownload(it) },
            onDismiss = { showAttachmentDownloads = false }
        )
    }

    if (deleteSessionTarget != null) {
        ChoiceDialog(
            title = "Delete Chat",
            body = "This will delete the chat and sync the change.",
            firstButtonLabel = "Delete",
            secondButtonLabel = "Cancel",
            isCritical = true,
            onFirst = {
                deleteSessionTarget?.let { session ->
                    store.deleteSession(session.id)
                }
                deleteSessionTarget = null
            },
            onSecond = { deleteSessionTarget = null },
            onDismiss = { deleteSessionTarget = null }
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
    attachmentDownloads: List<io.ente.ensu.domain.model.AttachmentDownloadItem>,
    attachmentDownloadProgress: Int?,
    onOpenDrawer: () -> Unit,
    onSignIn: () -> Unit,
    onAttachmentDownloads: () -> Unit
) {
    val titleText = sessionTitle?.takeIf { it.isNotBlank() } ?: "New Chat"

    TopAppBar(
        title = {
            if (showBrand) {
                EnsuLogo(height = 20.dp)
            } else {
                Text(
                    text = titleText,
                    style = EnsuTypography.h3Bold,
                    color = EnsuColor.textPrimary(),
                    maxLines = 1
                )
            }
        },
        navigationIcon = {
            IconButton(onClick = onOpenDrawer) {
                Icon(
                    imageVector = Icons.Outlined.Menu,
                    contentDescription = "Menu"
                )
            }
        },
        actions = {
            if (!isLoggedIn) {
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
                                imageVector = Icons.Outlined.Download,
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
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
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

