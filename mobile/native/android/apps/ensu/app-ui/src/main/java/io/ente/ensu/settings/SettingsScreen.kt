package io.ente.ensu.settings

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.designsystem.HugeIcons

@Composable
fun SettingsScreen(
    currentEndpoint: String,
    isLoggedIn: Boolean,
    userEmail: String?,
    onOpenLogs: () -> Unit,
    onSignOut: () -> Unit,
    onSignIn: () -> Unit,
    onDeleteAccount: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    val context = LocalContext.current

    val allItems = remember(context, onOpenLogs, onSignOut, onSignIn, onDeleteAccount, isLoggedIn) {
        buildList {
            add(
                SettingsItem(
                    title = "Logs",
                    subtitle = "View, export, and share logs",
                    onClick = onOpenLogs
                )
            )
            if (isLoggedIn) {
                add(
                    SettingsItem(
                        title = "Delete Account",
                        subtitle = "Email support to delete your account",
                        onClick = onDeleteAccount
                    )
                )
                add(
                    SettingsItem(
                        title = "Sign Out",
                        subtitle = "Stop syncing this device",
                        onClick = onSignOut
                    )
                )
            } else {
                add(
                    SettingsItem(
                        title = "Sign In to Backup",
                        subtitle = "Sync your chats across devices",
                        onClick = onSignIn
                    )
                )
            }

            add(
                SettingsItem(
                    title = "Privacy Policy",
                    subtitle = "ente.io/privacy",
                    onClick = { context.openExternalLink("https://ente.io/privacy") }
                )
            )
            add(
                SettingsItem(
                    title = "Terms of Service",
                    subtitle = "ente.io/terms",
                    onClick = { context.openExternalLink("https://ente.io/terms") }
                )
            )
        }
    }

    val filteredItems = remember(query, allItems) {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return@remember allItems
        allItems.filter { item ->
            item.title.lowercase().contains(q) ||
                (item.subtitle?.lowercase()?.contains(q) == true)
        }
    }

    Column(modifier = Modifier.padding(EnsuSpacing.pageHorizontal.dp)) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text(text = "Search settings", style = EnsuTypography.body) },
            singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = EnsuColor.fillFaint(),
                unfocusedContainerColor = EnsuColor.fillFaint(),
                focusedIndicatorColor = EnsuColor.fillFaint(),
                unfocusedIndicatorColor = EnsuColor.fillFaint()
            ),
            shape = RoundedCornerShape(EnsuCornerRadius.input.dp)
        )

        Spacer(modifier = Modifier.size(EnsuSpacing.lg.dp))

        if (isLoggedIn && !userEmail.isNullOrBlank()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(EnsuCornerRadius.card.dp))
                    .background(EnsuColor.fillFaint())
                    .padding(EnsuSpacing.lg.dp)
            ) {
                Text(
                    text = "Signed in as",
                    style = EnsuTypography.small,
                    color = EnsuColor.textMuted()
                )
                Text(
                    text = userEmail,
                    style = EnsuTypography.body,
                    color = EnsuColor.textPrimary()
                )
            }
            Spacer(modifier = Modifier.size(EnsuSpacing.md.dp))
        }

        val normalizedEndpoint = currentEndpoint.trim().trimEnd('/')
        val defaultEndpoint = "https://api.ente.io"
        val isCustomEndpoint = query.isBlank() && normalizedEndpoint.isNotBlank() && normalizedEndpoint != defaultEndpoint

        LazyColumn(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)) {
            items(filteredItems, key = { it.title }) { item ->
                SettingsRow(item)
                HorizontalDivider(color = EnsuColor.border())
            }

            if (isCustomEndpoint) {
                item(key = "endpoint") {
                    Spacer(modifier = Modifier.size(EnsuSpacing.sm.dp))
                    Text(
                        text = "Endpoint: $normalizedEndpoint",
                        style = EnsuTypography.small,
                        color = EnsuColor.textMuted(),
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = EnsuSpacing.sm.dp)
                    )
                }
            }
        }
    }
}

private data class SettingsItem(
    val title: String,
    val subtitle: String? = null,
    val onClick: () -> Unit
)

@Composable
private fun SettingsRow(item: SettingsItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = item.onClick)
            .padding(vertical = EnsuSpacing.sm.dp),
        horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = item.title, style = EnsuTypography.body, color = EnsuColor.textPrimary())
            if (!item.subtitle.isNullOrBlank()) {
                Text(text = item.subtitle, style = EnsuTypography.small, color = EnsuColor.textMuted())
            }
        }
        Icon(
            painter = painterResource(HugeIcons.ArrowRight01Icon),
            contentDescription = null,
            tint = EnsuColor.textMuted(),
            modifier = Modifier.size(18.dp)
        )
    }
}

private fun Context.openExternalLink(url: String) {
    runCatching {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        ContextCompat.startActivity(this, intent, null)
    }
}
