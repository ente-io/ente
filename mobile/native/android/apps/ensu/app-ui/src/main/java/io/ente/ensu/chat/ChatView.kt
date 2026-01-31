package io.ente.ensu.chat

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.weight
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.state.ChatState

@Composable
fun ChatView(
    chatState: ChatState,
    isDrawerOpen: Boolean,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onStop: () -> Unit,
    onCancelDownload: () -> Unit,
    onAttachmentSelected: (AttachmentType) -> Unit,
    onRemoveAttachment: (Attachment) -> Unit,
    onEditMessage: (ChatMessage) -> Unit,
    onRetryMessage: (ChatMessage) -> Unit,
    onCancelEdit: () -> Unit,
    onBranchChange: (String, Int) -> Unit,
    onOpenAttachment: (Attachment) -> Unit,
    onStartDownload: (Boolean) -> Unit,
    onOverflowTrim: () -> Unit,
    onOverflowIncreaseContext: () -> Unit,
    onOverflowCancel: () -> Unit
) {
    val showDownloadOnboarding by remember(
        chatState.isModelDownloaded,
        chatState.messages,
        chatState.isGenerating
    ) {
        derivedStateOf {
            !chatState.isModelDownloaded &&
                chatState.messages.isEmpty() &&
                !chatState.isGenerating
        }
    }

    val focusManager = LocalFocusManager.current
    var didAutoFocusInput by remember { mutableStateOf(false) }
    var focusRequestId by remember { mutableStateOf(0) }
    var wasDrawerOpen by remember { mutableStateOf(false) }

    val shouldAutoFocusInput = chatState.isModelDownloaded &&
        !showDownloadOnboarding &&
        !chatState.isDownloading &&
        !chatState.isGenerating &&
        !didAutoFocusInput &&
        !isDrawerOpen

    LaunchedEffect(shouldAutoFocusInput, isDrawerOpen) {
        if (isDrawerOpen) {
            focusManager.clearFocus()
            wasDrawerOpen = true
            return@LaunchedEffect
        }

        if (shouldAutoFocusInput) {
            focusRequestId += 1
            didAutoFocusInput = true
            wasDrawerOpen = false
            return@LaunchedEffect
        }

        if (wasDrawerOpen) {
            val shouldRestoreFocus = chatState.isModelDownloaded &&
                !showDownloadOnboarding &&
                !chatState.isDownloading &&
                !chatState.isGenerating
            if (shouldRestoreFocus) {
                focusRequestId += 1
            }
            wasDrawerOpen = false
        }
    }

    val shouldAutoDownload by remember(
        chatState.hasRequestedModelDownload,
        chatState.isDownloading,
        chatState.isGenerating
    ) {
        derivedStateOf {
            chatState.hasRequestedModelDownload &&
                !chatState.isDownloading &&
                !chatState.isGenerating
        }
    }

    LaunchedEffect(chatState.isModelDownloaded, shouldAutoDownload) {
        if (!chatState.isModelDownloaded && shouldAutoDownload) {
            onStartDownload(false)
        }
    }

    val sessionKey = chatState.currentSessionId ?: "new-session"

    val editingMessage by remember(chatState.editingMessageId, chatState.messages) {
        derivedStateOf {
            chatState.editingMessageId?.let { editingId ->
                chatState.messages.firstOrNull { it.id == editingId }
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .imePadding()
        ) {
            AnimatedContent(
                targetState = sessionKey,
                modifier = Modifier
                    .weight(1f),
                transitionSpec = {
                    val enter = fadeIn(animationSpec = tween(220, easing = FastOutSlowInEasing)) +
                        slideInVertically(animationSpec = tween(320, easing = FastOutSlowInEasing)) {
                            it / 12
                        }
                    val exit = fadeOut(animationSpec = tween(220, easing = FastOutSlowInEasing)) +
                        slideOutVertically(animationSpec = tween(320, easing = FastOutSlowInEasing)) {
                            -it / 12
                        }
                    enter.togetherWith(exit)
                },
                label = "session-change"
            ) {
                MessageList(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(
                            start = EnsuSpacing.pageHorizontal.dp,
                            end = EnsuSpacing.pageHorizontal.dp
                        ),
                    messages = chatState.messages,
                    streamingResponse = chatState.streamingResponse,
                    streamingParentId = chatState.streamingParentId,
                    isGenerating = chatState.isGenerating,
                    isModelDownloaded = chatState.isModelDownloaded,
                    isDownloading = chatState.isDownloading,
                    downloadPercent = chatState.downloadPercent,
                    downloadStatus = chatState.downloadStatus,
                    modelDownloadSizeBytes = chatState.modelDownloadSizeBytes,
                    branchSelections = chatState.branchSelections,
                    onEditMessage = onEditMessage,
                    onRetryMessage = onRetryMessage,
                    onBranchChange = onBranchChange,
                    onOpenAttachment = onOpenAttachment,
                    onStartDownload = onStartDownload
                )
            }

            chatState.overflowDialog?.let { overflow ->
                OverflowDialog(
                    state = overflow,
                    onTrim = onOverflowTrim,
                    onIncreaseContext = onOverflowIncreaseContext,
                    onCancel = onOverflowCancel
                )
            }

            if (!showDownloadOnboarding) {
                MessageInput(
                    modifier = Modifier
                        .fillMaxWidth()
                        .navigationBarsPadding()
                        .background(EnsuColor.backgroundBase()),
                    messageText = chatState.messageText,
                    attachments = chatState.attachments,
                    editingMessage = editingMessage,
                    isProcessingAttachments = chatState.isProcessingAttachments,
                    isGenerating = chatState.isGenerating,
                    isDownloading = chatState.isDownloading,
                    downloadPercent = chatState.downloadPercent,
                    isAttachmentDownloadBlocked = chatState.isAttachmentDownloadBlocked,
                    attachmentDownloadPercent = chatState.attachmentDownloadProgress,
                    onMessageChange = onMessageChange,
                    onSend = {
                        focusManager.clearFocus()
                        onSend()
                    },
                    onStop = onStop,
                    onAttachmentSelected = onAttachmentSelected,
                    onRemoveAttachment = onRemoveAttachment,
                    onCancelEdit = onCancelEdit,
                    focusRequestId = focusRequestId
                )
            }
        }

        val status = chatState.downloadStatus
        val isLoading = status?.contains("Loading", ignoreCase = true) == true
        val showToast by remember(status, chatState.isDownloading, showDownloadOnboarding, isLoading) {
            derivedStateOf {
                !showDownloadOnboarding &&
                    status != null &&
                    chatState.isDownloading &&
                    !isLoading
            }
        }
        if (showToast) {
            DownloadToastOverlay(
                status = status ?: "",
                percent = chatState.downloadPercent ?: 0,
                isLoading = isLoading,
                onCancel = onCancelDownload
            )
        }
    }
}
