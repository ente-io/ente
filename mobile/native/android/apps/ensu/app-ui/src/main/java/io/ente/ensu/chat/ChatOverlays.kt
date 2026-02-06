package io.ente.ensu.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.designsystem.HugeIcons
import io.ente.ensu.domain.state.OverflowDialogState
import io.ente.ensu.utils.rememberEnsuHaptics

@Composable
internal fun OverflowDialog(
    state: OverflowDialogState,
    onTrim: () -> Unit,
    onIncreaseContext: () -> Unit,
    onCancel: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text(text = "Context limit reached", style = EnsuTypography.h3) },
        text = {
            Text(
                text = "Input uses ${state.inputTokens} tokens (budget ${state.inputBudget}). Trim history or increase context size?",
                style = EnsuTypography.body,
                color = EnsuColor.textPrimary()
            )
        },
        confirmButton = {
            TextButton(onClick = onTrim) {
                Text(text = "Trim history", color = EnsuColor.textPrimary())
            }
        },
        dismissButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)) {
                TextButton(onClick = onIncreaseContext) {
                    Text(text = "Increase context", color = EnsuColor.textPrimary())
                }
                TextButton(onClick = onCancel) {
                    Text(text = "Cancel", color = EnsuColor.textMuted())
                }
            }
        },
        containerColor = EnsuColor.backgroundBase()
    )
}

@Composable
internal fun DownloadToastOverlay(
    status: String,
    percent: Int,
    isLoading: Boolean,
    onCancel: () -> Unit
) {
    val haptic = rememberEnsuHaptics()
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
                IconButton(
                    onClick = {
                        haptic.perform(HapticFeedbackType.LongPress)
                        onCancel()
                    },
                    modifier = Modifier.size(28.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(22.dp)
                            .background(EnsuColor.textPrimary(), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            painter = painterResource(HugeIcons.StopIcon),
                            contentDescription = "Cancel download",
                            modifier = Modifier.size(12.dp),
                            tint = EnsuColor.stopButton
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
            LinearProgressIndicator(
                progress = { clamped / 100f },
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
