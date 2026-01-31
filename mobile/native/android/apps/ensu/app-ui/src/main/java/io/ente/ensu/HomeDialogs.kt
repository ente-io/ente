package io.ente.ensu

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.AttachmentDownloadItem
import io.ente.ensu.domain.model.AttachmentDownloadStatus
import io.ente.ensu.domain.util.formattedFileSize

@Composable
internal fun ComingSoonDialog(
    title: String,
    message: String,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = title, style = EnsuTypography.h3Bold)
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(140.dp)
                        .background(
                            EnsuColor.fillFaint(),
                            RoundedCornerShape(EnsuCornerRadius.card.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "Illustration", style = EnsuTypography.small, color = EnsuColor.textMuted())
                }
                Text(text = message, style = EnsuTypography.body, color = EnsuColor.textMuted())
            }
        },
        confirmButton = {
            TextButton(
                onClick = onDismiss,
                colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textPrimary())
            ) {
                Text(text = "Got it")
            }
        },
        containerColor = EnsuColor.backgroundBase()
    )
}

@Composable
internal fun AttachmentDownloadsDialog(
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
                                    text = "Session ${item.sessionId.take(6)} • ${item.sizeBytes.formattedFileSize()}",
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
                                TextButton(
                                    onClick = { onCancel(item.id) },
                                    colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textPrimary())
                                ) {
                                    Text(text = "Cancel", style = EnsuTypography.mini)
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = onDismiss,
                colors = ButtonDefaults.textButtonColors(contentColor = EnsuColor.textPrimary())
            ) {
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
