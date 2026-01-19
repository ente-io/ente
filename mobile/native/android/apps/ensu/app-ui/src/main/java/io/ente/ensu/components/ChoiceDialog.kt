package io.ente.ensu.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuTypography

@Composable
fun ChoiceDialog(
    title: String,
    body: String,
    firstButtonLabel: String,
    secondButtonLabel: String? = null,
    isCritical: Boolean = false,
    isDismissible: Boolean = true,
    onFirst: () -> Unit,
    onSecond: (() -> Unit)? = null,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = { if (isDismissible) onDismiss() },
        title = { Text(text = title, style = EnsuTypography.h3) },
        text = { Text(text = body, style = EnsuTypography.body) },
        confirmButton = {
            Button(
                onClick = onFirst,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isCritical) EnsuColor.error else EnsuColor.accent()
                )
            ) {
                Text(text = firstButtonLabel)
            }
        },
        dismissButton = {
            if (secondButtonLabel != null && onSecond != null) {
                TextButton(onClick = onSecond) {
                    Text(text = secondButtonLabel)
                }
            }
        }
    )
}
