package io.ente.ensu.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.model.LogLevel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun LogViewerScreen(logs: List<LogEntry>) {
    var selectedLog by remember { mutableStateOf<LogEntry?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(EnsuSpacing.pageHorizontal.dp)
    ) {
        if (logs.isEmpty()) {
            Text(text = "No logs available", style = EnsuTypography.body, color = EnsuColor.textMuted())
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)) {
                items(logs, key = { it.id }) { log ->
                    LogRow(logEntry = log, onOpenDetails = { selectedLog = log })
                }
            }
        }
    }

    selectedLog?.let { log ->
        AlertDialog(
            onDismissRequest = { selectedLog = null },
            title = { Text(text = "Log details", style = EnsuTypography.h3) },
            text = {
                Column {
                    Text(text = log.message, style = EnsuTypography.body)
                    log.details?.let { details ->
                        Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
                        Text(text = details, style = EnsuTypography.small, color = EnsuColor.textMuted())
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { selectedLog = null }) {
                    Text(text = "Close")
                }
            }
        )
    }
}

@Composable
private fun LogRow(logEntry: LogEntry, onOpenDetails: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = EnsuSpacing.xs.dp)
    ) {
        Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            Text(
                text = logEntry.level.name,
                style = EnsuTypography.mini,
                color = levelColor(logEntry.level)
            )
            Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
            Text(
                text = logTimestampFormatter.format(Date(logEntry.timestampMillis)),
                style = EnsuTypography.mini,
                color = EnsuColor.textMuted()
            )
        }
        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
        Text(text = logEntry.message, style = EnsuTypography.body)
        TextButton(onClick = onOpenDetails) {
            Text(text = "Details", style = EnsuTypography.small, color = EnsuColor.accent())
        }
    }
}

@Composable
private fun levelColor(level: LogLevel): Color = when (level) {
    LogLevel.Info -> EnsuColor.textMuted()
    LogLevel.Warning -> EnsuColor.accent()
    LogLevel.Error -> EnsuColor.error
}

private val logTimestampFormatter = SimpleDateFormat("h:mm:ss a", Locale.getDefault())
