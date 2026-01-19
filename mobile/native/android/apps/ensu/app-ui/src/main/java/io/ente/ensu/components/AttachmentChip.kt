package io.ente.ensu.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuTypography

@Composable
fun AttachmentChip(
    name: String,
    size: String,
    icon: ImageVector,
    isUploading: Boolean,
    onDelete: (() -> Unit)? = null
) {
    AssistChip(
        onClick = { onDelete?.invoke() },
        label = {
            Column(verticalArrangement = Arrangement.Center) {
                Text(text = name, style = EnsuTypography.small, maxLines = 1)
                Text(text = size, style = EnsuTypography.mini, color = EnsuColor.textMuted())
            }
        },
        leadingIcon = {
            Icon(imageVector = icon, contentDescription = null, modifier = Modifier.size(16.dp))
        },
        trailingIcon = {
            if (isUploading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(12.dp),
                    strokeWidth = 2.dp
                )
            }
        },
        colors = AssistChipDefaults.assistChipColors(containerColor = EnsuColor.fillFaint())
    )
}
