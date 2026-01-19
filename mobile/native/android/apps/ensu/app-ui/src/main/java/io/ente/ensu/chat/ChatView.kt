package io.ente.ensu.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
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

@Composable
fun ChatView(
    chatState: ChatState,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onStop: () -> Unit,
    onAttachmentSelected: (AttachmentType) -> Unit,
    onBranchChange: (String, Int) -> Unit
) {
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
            branchSelections = chatState.branchSelections,
            onBranchChange = onBranchChange
        )

        MessageInput(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .background(EnsuColor.backgroundBase()),
            messageText = chatState.messageText,
            attachments = chatState.attachments,
            isProcessingAttachments = chatState.isProcessingAttachments,
            isGenerating = chatState.isGenerating,
            isDownloading = chatState.isDownloading,
            onMessageChange = onMessageChange,
            onSend = onSend,
            onStop = onStop,
            onAttachmentSelected = onAttachmentSelected
        )
    }
}

@Composable
private fun MessageList(
    modifier: Modifier,
    messages: List<ChatMessage>,
    branchSelections: Map<String, Int>,
    onBranchChange: (String, Int) -> Unit
) {
    if (messages.isEmpty()) {
        EmptyState(modifier = modifier)
        return
    }

    LazyColumn(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.lg.dp)
    ) {
        items(messages, key = { it.id }) { message ->
            when (message.author) {
                MessageAuthor.User -> {
                    UserMessageBubble(
                        message = message,
                        branchSelections = branchSelections,
                        onBranchChange = onBranchChange
                    )
                }
                MessageAuthor.Assistant -> {
                    AssistantMessageBubble(
                        message = message,
                        branchSelections = branchSelections,
                        onBranchChange = onBranchChange
                    )
                }
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

@Composable
private fun UserMessageBubble(
    message: ChatMessage,
    branchSelections: Map<String, Int>,
    onBranchChange: (String, Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = EnsuSpacing.messageBubbleInset.dp),
        horizontalAlignment = Alignment.End
    ) {
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
                onTap = {},
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
    onBranchChange: (String, Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(end = EnsuSpacing.messageBubbleInset.dp),
        horizontalAlignment = Alignment.Start
    ) {
        Text(
            text = message.text,
            style = EnsuTypography.message,
            color = EnsuColor.textPrimary()
        )

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
                onTap = {},
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

        Row(verticalAlignment = Alignment.CenterVertically) {
            TimestampText(message.timestampMillis)
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
private fun MessageInput(
    modifier: Modifier,
    messageText: String,
    attachments: List<Attachment>,
    isProcessingAttachments: Boolean,
    isGenerating: Boolean,
    isDownloading: Boolean,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onStop: () -> Unit,
    onAttachmentSelected: (AttachmentType) -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    val placeholder = if (isDownloading) {
        "Downloading model... (queue messages)"
    } else {
        "Compose your message..."
    }

    Column(
        modifier = modifier
            .background(EnsuColor.backgroundBase()),
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
    ) {
        if (attachments.isNotEmpty()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = EnsuSpacing.pageHorizontal.dp),
                horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
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
                        isUploading = attachment.isUploading
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

                IconButton(
                    onClick = if (isGenerating) onStop else onSend,
                    enabled = !isDownloading,
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
