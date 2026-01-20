package io.ente.ensu.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.outlined.AttachFile
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.StopCircle
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Code
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import io.ente.ensu.components.ActionButton
import io.ente.ensu.components.BranchSwitcher
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.MessageAuthor
import io.ente.ensu.domain.state.ChatState
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.delay

@Composable
fun ChatView(
    chatState: ChatState,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onStop: () -> Unit,
    onCancelDownload: () -> Unit,
    onAttachmentSelected: (AttachmentType) -> Unit,
    onRemoveAttachment: (Attachment) -> Unit,
    onEditMessage: (ChatMessage) -> Unit,
    onRetryMessage: (ChatMessage) -> Unit,
    onCancelEdit: () -> Unit,
    onBranchChange: (String, Int) -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            MessageList(
                modifier = Modifier
                    .weight(1f)
                    .padding(
                        start = EnsuSpacing.pageHorizontal.dp,
                        end = EnsuSpacing.pageHorizontal.dp,
                        top = EnsuSpacing.pageVertical.dp
                    ),
                messages = chatState.messages,
                streamingResponse = chatState.streamingResponse,
                streamingParentId = chatState.streamingParentId,
                isGenerating = chatState.isGenerating,
                branchSelections = chatState.branchSelections,
                onEditMessage = onEditMessage,
                onRetryMessage = onRetryMessage,
                onBranchChange = onBranchChange
            )

            val editingMessage = chatState.editingMessageId?.let { editingId ->
                chatState.messages.firstOrNull { it.id == editingId }
            }

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
                onMessageChange = onMessageChange,
                onSend = onSend,
                onStop = onStop,
                onAttachmentSelected = onAttachmentSelected,
                onRemoveAttachment = onRemoveAttachment,
                onCancelEdit = onCancelEdit
            )
        }

        val status = chatState.downloadStatus
        val showToast = status != null && (chatState.isDownloading || status.contains("Loading", ignoreCase = true))
        if (showToast) {
            DownloadToastOverlay(
                status = status ?: "",
                percent = chatState.downloadPercent ?: 0,
                isLoading = status?.contains("Loading", ignoreCase = true) == true,
                onCancel = onCancelDownload
            )
        }
    }
}

@Composable
private fun MessageList(
    modifier: Modifier,
    messages: List<ChatMessage>,
    streamingResponse: String,
    streamingParentId: String?,
    isGenerating: Boolean,
    branchSelections: Map<String, Int>,
    onEditMessage: (ChatMessage) -> Unit,
    onRetryMessage: (ChatMessage) -> Unit,
    onBranchChange: (String, Int) -> Unit
) {
    if (messages.isEmpty() && !isGenerating) {
        EmptyState(modifier = modifier)
        return
    }

    val listState = rememberLazyListState()
    var autoScrollEnabled by remember { mutableStateOf(true) }
    val isAtBottom by remember {
        derivedStateOf {
            val layoutInfo = listState.layoutInfo
            val totalItems = layoutInfo.totalItemsCount
            if (totalItems == 0) {
                true
            } else {
                val lastVisible = layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0
                lastVisible >= totalItems - 1
            }
        }
    }

    LaunchedEffect(isGenerating) {
        if (isGenerating) {
            autoScrollEnabled = true
        }
    }

    LaunchedEffect(listState.isScrollInProgress, isAtBottom) {
        if (listState.isScrollInProgress && !isAtBottom) {
            autoScrollEnabled = false
        }
    }

    LaunchedEffect(messages.size, streamingResponse, streamingParentId, isGenerating, autoScrollEnabled) {
        if (!autoScrollEnabled) return@LaunchedEffect
        if (messages.isEmpty()) return@LaunchedEffect
        val targetIndex = messages.lastIndex
        if (targetIndex >= 0) {
            listState.animateScrollToItem(targetIndex)
        }
    }

    LazyColumn(
        modifier = modifier,
        state = listState,
        contentPadding = PaddingValues(bottom = (EnsuSpacing.xxxl + EnsuSpacing.xl).dp),
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.lg.dp)
    ) {
        items(messages, key = { it.id }) { message ->
            when (message.author) {
                MessageAuthor.User -> {
                    UserMessageBubble(
                        message = message,
                        branchSelections = branchSelections,
                        onEdit = { onEditMessage(message) },
                        onBranchChange = onBranchChange
                    )
                }
                MessageAuthor.Assistant -> {
                    AssistantMessageBubble(
                        message = message,
                        branchSelections = branchSelections,
                        onRetry = { onRetryMessage(message) },
                        onBranchChange = onBranchChange
                    )
                }
            }

            if (isGenerating && streamingParentId == message.id) {
                Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
                StreamingMessageBubble(text = streamingResponse)
            }
        }

        if (isGenerating && streamingParentId == null) {
            items(1) {
                StreamingMessageBubble(text = streamingResponse)
            }
        }
    }
}

@Composable
private fun EmptyState(modifier: Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "Start typing to begin a conversation",
            style = EnsuTypography.body,
            color = EnsuColor.textMuted(),
            textAlign = TextAlign.Center
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun UserMessageBubble(
    message: ChatMessage,
    branchSelections: Map<String, Int>,
    onEdit: () -> Unit,
    onBranchChange: (String, Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = EnsuSpacing.messageBubbleInset.dp),
        horizontalAlignment = Alignment.End
    ) {
        if (message.attachments.isNotEmpty()) {
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp, Alignment.End),
                verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
            ) {
                message.attachments.forEach { attachment ->
                    val icon = when (attachment.type) {
                        AttachmentType.Image -> Icons.Outlined.Image
                        AttachmentType.Document -> Icons.Outlined.Description
                    }
                    io.ente.ensu.components.AttachmentChip(
                        name = attachment.name,
                        size = "${attachment.sizeBytes / 1024} KB",
                        icon = icon,
                        isUploading = attachment.isUploading
                    )
                }
            }
            Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
        }

        Text(
            text = message.text,
            style = EnsuTypography.message,
            color = EnsuColor.userMessageText(),
            textAlign = TextAlign.Right
        )

        Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))

        Row(horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
            ActionButton(
                icon = Icons.Outlined.Edit,
                onTap = onEdit,
                contentDescription = "Edit"
            )
            ActionButton(
                icon = Icons.Outlined.ContentCopy,
                onTap = {},
                contentDescription = "Copy"
            )
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))

        Row(verticalAlignment = Alignment.CenterVertically) {
            Spacer(modifier = Modifier.weight(1f))
            if (message.branchCount > 1) {
                BranchSwitcher(
                    currentIndex = branchSelections[message.id] ?: 1,
                    totalCount = message.branchCount,
                    onPrevious = {
                        val current = branchSelections[message.id] ?: 1
                        onBranchChange(message.id, (current - 1).coerceAtLeast(1))
                    },
                    onNext = {
                        val current = branchSelections[message.id] ?: 1
                        onBranchChange(message.id, (current + 1).coerceAtMost(message.branchCount))
                    }
                )
                Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
            }
            TimestampText(message.timestampMillis)
        }
    }
}

@Composable
private fun AssistantMessageBubble(
    message: ChatMessage,
    branchSelections: Map<String, Int>,
    onRetry: () -> Unit,
    onBranchChange: (String, Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(end = EnsuSpacing.messageBubbleInset.dp),
        horizontalAlignment = Alignment.Start
    ) {
        MarkdownView(markdown = message.text)

        if (message.isInterrupted) {
            Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
            Text(
                text = "Interrupted",
                style = EnsuTypography.small,
                color = EnsuColor.textMuted()
            )
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))

        Row(verticalAlignment = Alignment.CenterVertically) {
            ActionButton(
                icon = Icons.Outlined.ContentCopy,
                onTap = {},
                contentDescription = "Copy"
            )
            ActionButton(
                icon = Icons.Outlined.Code,
                onTap = {},
                contentDescription = "Raw"
            )
            ActionButton(
                icon = Icons.Outlined.Refresh,
                onTap = onRetry,
                contentDescription = "Retry"
            )
            message.tokensPerSecond?.let { tokPerSec ->
                Text(
                    text = String.format(Locale.US, "%.1f tok/s", tokPerSec),
                    style = EnsuTypography.mini,
                    color = EnsuColor.textMuted()
                )
            }
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp), verticalAlignment = Alignment.CenterVertically) {
            TimestampText(message.timestampMillis)
            if (message.branchCount > 1) {
                BranchSwitcher(
                    currentIndex = branchSelections[message.id] ?: 1,
                    totalCount = message.branchCount,
                    onPrevious = {
                        val current = branchSelections[message.id] ?: 1
                        onBranchChange(message.id, (current - 1).coerceAtLeast(1))
                    },
                    onNext = {
                        val current = branchSelections[message.id] ?: 1
                        onBranchChange(message.id, (current + 1).coerceAtMost(message.branchCount))
                    }
                )
            }
        }
    }
}

@Composable
private fun StreamingMessageBubble(text: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(end = EnsuSpacing.messageBubbleInset.dp),
        horizontalAlignment = Alignment.Start
    ) {
        if (text.isBlank()) {
            LoadingDotsText()
        } else {
            Text(
                text = text,
                style = EnsuTypography.message,
                color = EnsuColor.textPrimary()
            )
        }
    }
}

@Composable
private fun LoadingDotsText() {
    var dotCount by remember { mutableStateOf(1) }

    LaunchedEffect(Unit) {
        while (true) {
            delay(450)
            dotCount = if (dotCount == 3) 1 else dotCount + 1
        }
    }

    Text(
        text = ".".repeat(dotCount),
        style = EnsuTypography.message,
        color = EnsuColor.textMuted()
    )
}

@Composable
private fun DownloadToastOverlay(
    status: String,
    percent: Int,
    isLoading: Boolean,
    onCancel: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = EnsuSpacing.lg.dp),
        contentAlignment = Alignment.TopCenter
    ) {
        val title = if (isLoading) "Loading model" else "Downloading model"
        val clamped = percent.coerceIn(0, 100)
        Column(
            modifier = Modifier
                .padding(horizontal = EnsuSpacing.lg.dp)
                .background(EnsuColor.fillFaint(), RoundedCornerShape(EnsuCornerRadius.toast.dp))
                .padding(EnsuSpacing.lg.dp)
                .fillMaxWidth()
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = title, style = EnsuTypography.large, color = EnsuColor.textPrimary())
                Spacer(modifier = Modifier.weight(1f))
                IconButton(onClick = onCancel, modifier = Modifier.size(28.dp)) {
                    Icon(
                        imageVector = Icons.Outlined.StopCircle,
                        contentDescription = "Cancel download",
                        tint = EnsuColor.stopButton
                    )
                }
            }
            Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
            LinearProgressIndicator(
                progress = clamped / 100f,
                color = if (isLoading) EnsuColor.accent() else EnsuColor.accent(),
                trackColor = EnsuColor.border(),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = status, style = EnsuTypography.small, color = EnsuColor.textMuted())
                Spacer(modifier = Modifier.weight(1f))
                Text(text = "$clamped%", style = EnsuTypography.mini, color = EnsuColor.textMuted())
            }
        }
    }
}

@Composable
private fun TimestampText(timestampMillis: Long) {
    Text(
        text = timestampFormatter.format(Date(timestampMillis)),
        style = EnsuTypography.mini,
        color = EnsuColor.textMuted()
    )
}

@Composable
private fun EditBanner(message: ChatMessage, onCancelEdit: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.pageHorizontal.dp)
            .background(EnsuColor.fillFaint(), RoundedCornerShape(EnsuCornerRadius.input.dp))
            .height(IntrinsicSize.Min)
    ) {
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .width(3.dp)
                .background(EnsuColor.accent())
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = EnsuSpacing.md.dp, vertical = EnsuSpacing.sm.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Outlined.Edit,
                contentDescription = null,
                tint = EnsuColor.accent(),
                modifier = Modifier.size(14.dp)
            )
            Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
            Text(
                text = "Editing:",
                style = EnsuTypography.small,
                color = EnsuColor.textMuted()
            )
            Spacer(modifier = Modifier.width(EnsuSpacing.xs.dp))
            Text(
                text = message.text,
                style = EnsuTypography.small,
                color = EnsuColor.textPrimary(),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
            IconButton(onClick = onCancelEdit, modifier = Modifier.size(24.dp)) {
                Icon(
                    imageVector = Icons.Outlined.Close,
                    contentDescription = "Cancel edit",
                    tint = EnsuColor.textMuted()
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun MessageInput(
    modifier: Modifier,
    messageText: String,
    attachments: List<Attachment>,
    editingMessage: ChatMessage?,
    isProcessingAttachments: Boolean,
    isGenerating: Boolean,
    isDownloading: Boolean,
    downloadPercent: Int?,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onStop: () -> Unit,
    onAttachmentSelected: (AttachmentType) -> Unit,
    onRemoveAttachment: (Attachment) -> Unit,
    onCancelEdit: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    val placeholder = if (isDownloading) {
        val percent = downloadPercent?.let { " ($it%)" } ?: ""
        "Downloading model...$percent"
    } else {
        "Compose your message..."
    }

    Column(
        modifier = modifier
            .background(EnsuColor.backgroundBase()),
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
    ) {
        if (editingMessage != null) {
            EditBanner(message = editingMessage, onCancelEdit = onCancelEdit)
        }

        if (attachments.isNotEmpty()) {
            val maxAttachmentHeight = 140.dp
            FlowRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = maxAttachmentHeight)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = EnsuSpacing.pageHorizontal.dp),
                horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp),
                verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
            ) {
                attachments.forEach { attachment ->
                    val icon = when (attachment.type) {
                        AttachmentType.Image -> Icons.Outlined.Image
                        AttachmentType.Document -> Icons.Outlined.Description
                    }
                    io.ente.ensu.components.AttachmentChip(
                        name = attachment.name,
                        size = "${attachment.sizeBytes / 1024} KB",
                        icon = icon,
                        isUploading = attachment.isUploading,
                        onDelete = { onRemoveAttachment(attachment) }
                    )
                }
            }
        }

        if (isProcessingAttachments) {
            Row(
                modifier = Modifier.padding(horizontal = EnsuSpacing.pageHorizontal.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
                Text(text = "Reading attachment...", style = EnsuTypography.small)
            }
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                .padding(bottom = EnsuSpacing.sm.dp)
                .background(EnsuColor.fillFaint(), RoundedCornerShape(EnsuCornerRadius.input.dp))
                .padding(
                    horizontal = EnsuSpacing.inputHorizontal.dp,
                    vertical = EnsuSpacing.inputVertical.dp
                )
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                BasicTextField(
                    value = messageText,
                    onValueChange = onMessageChange,
                    modifier = Modifier.weight(1f),
                    textStyle = EnsuTypography.message.copy(color = EnsuColor.textPrimary()),
                    minLines = 1,
                    maxLines = 5,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                    cursorBrush = SolidColor(EnsuColor.accent())
                ) { innerTextField ->
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterStart) {
                        if (messageText.isBlank()) {
                            Text(
                                text = placeholder,
                                style = EnsuTypography.message,
                                color = EnsuColor.textMuted()
                            )
                        }
                        innerTextField()
                    }
                }

                Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))

                if (editingMessage == null) {
                    Box {
                        IconButton(
                            onClick = { showMenu = true },
                            enabled = !isGenerating && !isDownloading,
                            modifier = Modifier.size(36.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.AttachFile,
                                contentDescription = "Attach"
                            )
                        }
                        DropdownMenu(expanded = showMenu, onDismissRequest = { showMenu = false }) {
                            DropdownMenuItem(
                                text = { Text(text = "Image") },
                                onClick = {
                                    showMenu = false
                                    onAttachmentSelected(AttachmentType.Image)
                                }
                            )
                            DropdownMenuItem(
                                text = { Text(text = "Document") },
                                onClick = {
                                    showMenu = false
                                    onAttachmentSelected(AttachmentType.Document)
                                }
                            )
                        }
                    }
                }

                val canSend = messageText.isNotBlank() || attachments.isNotEmpty()

                IconButton(
                    onClick = if (isGenerating) onStop else onSend,
                    enabled = !isDownloading && (isGenerating || canSend),
                    modifier = Modifier.size(36.dp)
                ) {
                    val icon = when {
                        isGenerating -> Icons.Outlined.StopCircle
                        isDownloading -> Icons.Outlined.Download
                        else -> Icons.AutoMirrored.Outlined.ArrowForward
                    }
                    val tint = when {
                        isGenerating -> EnsuColor.stopButton
                        isDownloading -> EnsuColor.textMuted()
                        else -> EnsuColor.textMuted()
                    }
                    Icon(
                        imageVector = icon,
                        contentDescription = "Send",
                        modifier = Modifier.size(22.dp),
                        tint = tint
                    )
                }
            }
        }
    }
}

private val timestampFormatter = SimpleDateFormat("h:mm a", Locale.getDefault())
