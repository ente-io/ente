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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Info
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
import androidx.compose.ui.graphics.vector.ImageVector
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
                    title = "About",
                    iconVector = Icons.Outlined.Info,
                    onClick = { context.openExternalLink("https://ente.io/blog/ensu/") }
                )
            )

            add(
                SettingsItem(
                    title = "Logs",
                    iconRes = HugeIcons.Bug01Icon,
                    onClick = onOpenLogs
                )
            )

            if (isLoggedIn) {
                add(
                    SettingsItem(
                        title = "Delete Account",
                        iconRes = HugeIcons.Delete01Icon,
                        onClick = onDeleteAccount,
                        isDestructive = true
                    )
                )
                add(
                    SettingsItem(
                        title = "Sign Out",
                        iconRes = HugeIcons.Cancel01Icon,
                        onClick = onSignOut,
                        isDestructive = true
                    )
                )
            } else {
                add(
                    SettingsItem(
                        title = "Sign In to Backup",
                        iconRes = HugeIcons.Settings01Icon,
                        onClick = onSignIn
                    )
                )
            }

            add(
                SettingsItem(
                    title = "Privacy Policy",
                    iconRes = HugeIcons.ViewIcon,
                    onClick = { context.openExternalLink("https://ente.io/privacy") }
                )
            )
            add(
                SettingsItem(
                    title = "Terms of Service",
                    iconVector = Icons.Outlined.Description,
                    onClick = { context.openExternalLink("https://ente.io/terms") }
                )
            )
        }
    }

    val filteredItems = remember(query, allItems) {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return@remember allItems
        allItems.filter { item ->
            item.title.lowercase().contains(q)
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

        LazyColumn(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)) {
            items(filteredItems, key = { it.title }) { item ->
                SettingsRow(item)
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
    val iconRes: Int? = null,
    val iconVector: ImageVector? = null,
    val onClick: () -> Unit,
    val isDestructive: Boolean = false
)

@Composable
private fun SettingsRow(item: SettingsItem) {
    val iconAndTextColor = if (item.isDestructive) EnsuColor.error else EnsuColor.textPrimary()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(EnsuCornerRadius.card.dp))
            .background(EnsuColor.fillFaint())
            .clickable(onClick = item.onClick)
            .padding(horizontal = EnsuSpacing.lg.dp, vertical = EnsuSpacing.lg.dp),
        horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        item.iconVector?.let { iconVector ->
            Icon(
                imageVector = iconVector,
                contentDescription = null,
                tint = iconAndTextColor,
                modifier = Modifier.size(18.dp)
            )
        } ?: item.iconRes?.let { iconRes ->
            Icon(
                painter = painterResource(iconRes),
                contentDescription = null,
                tint = iconAndTextColor,
                modifier = Modifier.size(18.dp)
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(text = item.title, style = EnsuTypography.body, color = iconAndTextColor)
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
