package io.ente.ensu.components

import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuTypography

@Composable
fun ActionButton(
    icon: ImageVector,
    onTap: () -> Unit,
    contentDescription: String,
    color: Color = EnsuColor.textMuted()
) {
    IconButton(
        onClick = onTap,
        modifier = Modifier.size(36.dp),
        colors = IconButtonDefaults.iconButtonColors(contentColor = color)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            modifier = Modifier.size(16.dp)
        )
    }
}

@Composable
fun TextActionButton(
    text: String,
    onTap: () -> Unit
) {
    TextButton(onClick = onTap) {
        Text(text = text, style = EnsuTypography.small, color = EnsuColor.textMuted())
    }
}
