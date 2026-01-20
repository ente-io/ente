@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
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
import io.ente.ensu.domain.model.Attachment
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
                                showBrand = appState.chat.messages.isEmpty(),
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
                            onBranchChange = store::updateBranchSelection
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

    val destination = File(attachmentsDir, "${UUID.randomUUID()}_$safeName")
    return runCatching {
        val inputStream = resolver.openInputStream(uri) ?: return@runCatching null

        inputStream.use { input ->
            FileOutputStream(destination).use { output ->
                input.copyTo(output)
            }
        }

        val finalSize = destination.length().takeIf { it > 0 } ?: size ?: 0L

        Attachment(
            name = name ?: destination.name,
            sizeBytes = finalSize,
            type = type,
            localPath = destination.absolutePath,
            isUploading = false
        )
    }.getOrNull()
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

