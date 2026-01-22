package io.ente.ensu.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Cloud
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.ente.ensu.components.EnsuLogo
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.HugeIcons
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.model.ChatSession
import kotlin.math.absoluteValue

@Composable
fun SessionDrawer(
    sessions: List<ChatSession>,
    selectedSessionId: String?,
    isLoggedIn: Boolean,
    userEmail: String?,
    onNewChat: () -> Unit,
    onSelectSession: (ChatSession) -> Unit,
    onDeleteSession: (ChatSession) -> Unit,
    onSync: () -> Unit,
    onOpenSettings: () -> Unit,
    onDeveloperTap: () -> Unit,
    onSignIn: () -> Unit,
    onSignOut: () -> Unit
) {
    ModalDrawerSheet(
        drawerContainerColor = EnsuColor.backgroundBase(),
        drawerShape = RectangleShape
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.systemBars)
        ) {
            DrawerHeader(
                isLoggedIn = isLoggedIn,
                userEmail = userEmail,
                onOpenSettings = onOpenSettings,
                onDeveloperTap = onDeveloperTap
            )

            HorizontalDivider(color = EnsuColor.border())

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = EnsuSpacing.lg.dp),
                verticalArrangement = Arrangement.spacedBy(EnsuSpacing.lg.dp)
            ) {
                DrawerNewChat(
                    onNewChat = onNewChat,
                    onSync = onSync,
                    isLoggedIn = isLoggedIn
                )
                SessionGroups(
                    sessions = sessions,
                    selectedSessionId = selectedSessionId,
                    onSelectSession = onSelectSession,
                    onDeleteSession = onDeleteSession
                )
            }

            HorizontalDivider(color = EnsuColor.border())

            DrawerFooter(
                isLoggedIn = isLoggedIn,
                onSignIn = onSignIn,
                onSignOut = onSignOut
            )
        }
    }
}

@Composable
private fun DrawerHeader(
    isLoggedIn: Boolean,
    userEmail: String?,
    onOpenSettings: () -> Unit,
    onDeveloperTap: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(EnsuColor.backgroundBase())
            .padding(EnsuSpacing.lg.dp),
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .clickable { onDeveloperTap() }
            ) {
                EnsuLogo(height = 28.dp)
            }
            Spacer(modifier = Modifier.weight(1f))
            DrawerIconButton(
                iconRes = HugeIcons.Settings01Icon,
                contentDescription = "Settings",
                onClick = onOpenSettings
            )
        }

        if (isLoggedIn && !userEmail.isNullOrBlank()) {
            CloudBadge(email = userEmail)
        }
    }
}

@Composable
private fun DrawerIconButton(
    iconRes: Int,
    contentDescription: String,
    onClick: () -> Unit,
    isEnabled: Boolean = true
) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clickable(enabled = isEnabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            painter = painterResource(iconRes),
            contentDescription = contentDescription,
            modifier = Modifier.size(18.dp),
            tint = if (isEnabled) EnsuColor.textPrimary() else EnsuColor.textMuted()
        )
    }
}

@Composable
private fun DrawerPrimaryTile(
    iconRes: Int,
    label: String,
    onClick: () -> Unit,
    isEnabled: Boolean,
    modifier: Modifier = Modifier
) {
    val tint = if (isEnabled) EnsuColor.textPrimary() else EnsuColor.textMuted()

    Row(
        modifier = modifier
            .clip(RoundedCornerShape(EnsuCornerRadius.card.dp))
            .background(EnsuColor.fillFaint())
            .clickable(enabled = isEnabled, onClick = onClick)
            .padding(horizontal = EnsuSpacing.lg.dp, vertical = EnsuSpacing.md.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Icon(
            painter = painterResource(iconRes),
            contentDescription = label,
            modifier = Modifier.size(18.dp),
            tint = tint
        )
        Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
        Text(text = label, style = EnsuTypography.body, color = tint)
    }
}

@Composable
private fun CloudBadge(email: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(RoundedCornerShape(EnsuCornerRadius.card.dp))
            .background(EnsuColor.fillFaint())
            .padding(horizontal = EnsuSpacing.md.dp, vertical = EnsuSpacing.sm.dp)
    ) {
        Icon(
            imageVector = Icons.Outlined.Cloud,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = EnsuColor.textMuted()
        )
        Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
        Text(
            text = email,
            style = EnsuTypography.small,
            color = EnsuColor.textMuted(),
            maxLines = 1
        )
    }
}

@Composable
private fun DrawerNewChat(
    onNewChat: () -> Unit,
    onSync: () -> Unit,
    isLoggedIn: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.lg.dp),
        horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
    ) {
        DrawerPrimaryTile(
            iconRes = HugeIcons.PlusSignIcon,
            label = "New Chat",
            onClick = onNewChat,
            isEnabled = true,
            modifier = Modifier.weight(1f)
        )

        if (isLoggedIn) {
            DrawerPrimaryTile(
                iconRes = HugeIcons.ArrowReloadHorizontalIcon,
                label = "Sync",
                onClick = onSync,
                isEnabled = true,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun SessionGroups(
    sessions: List<ChatSession>,
    selectedSessionId: String?,
    onSelectSession: (ChatSession) -> Unit,
    onDeleteSession: (ChatSession) -> Unit
) {
    val grouped = sessions.groupBy { sessionGroupLabel(it.updatedAtMillis) }
    val order = listOf("TODAY", "YESTERDAY", "THIS WEEK", "LAST WEEK", "THIS MONTH", "OLDER")

    Column(
        modifier = Modifier.fillMaxWidth(),
        // iOS uses `VStack(..., spacing: EnsuSpacing.lg)`, but Compose text metrics
        // make this look a bit looser, so we tighten slightly.
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)
    ) {
        order.forEach { label ->
            val groupSessions = grouped[label] ?: return@forEach

            Column(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)) {
                Text(
                    text = label,
                    style = EnsuTypography.tiny.copy(letterSpacing = 1.sp),
                    color = EnsuColor.textMuted(),
                    modifier = Modifier.padding(horizontal = EnsuSpacing.lg.dp)
                )

                groupSessions.forEach { session ->
                    SessionTile(
                        session = session,
                        isSelected = session.id == selectedSessionId,
                        onSelect = { onSelectSession(session) },
                        onDelete = { onDeleteSession(session) }
                    )
                }
            }
        }
    }
}

@Composable
private fun SessionTile(
    session: ChatSession,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onDelete: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onSelect)
            .padding(horizontal = EnsuSpacing.lg.dp, vertical = EnsuSpacing.sm.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = session.title,
                    style = if (isSelected) EnsuTypography.body else EnsuTypography.small,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                    color = EnsuColor.textPrimary(),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                val subtitle = session.lastMessagePreview ?: "Nothing here"
                Text(
                    text = subtitle,
                    style = EnsuTypography.mini,
                    color = EnsuColor.textMuted(),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .clickable(onClick = onDelete),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    painter = painterResource(HugeIcons.Delete01Icon),
                    contentDescription = "Delete",
                    modifier = Modifier.size(18.dp),
                    tint = EnsuColor.textMuted()
                )
            }
        }
    }
}

@Composable
private fun DrawerFooter(
    isLoggedIn: Boolean,
    onSignIn: () -> Unit,
    onSignOut: () -> Unit
) {
    val label = if (isLoggedIn) "Sign Out" else "Sign In to Backup"
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = if (isLoggedIn) onSignOut else onSignIn)
            .padding(EnsuSpacing.lg.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label, style = EnsuTypography.body, color = EnsuColor.textPrimary())
    }
}

private fun sessionGroupLabel(updatedAtMillis: Long): String {
    val now = System.currentTimeMillis()
    val dayMillis = 86_400_000L
    val daysAgo = ((now - updatedAtMillis) / dayMillis).absoluteValue
    return when {
        daysAgo == 0L -> "TODAY"
        daysAgo == 1L -> "YESTERDAY"
        daysAgo < 7L -> "THIS WEEK"
        daysAgo < 14L -> "LAST WEEK"
        daysAgo < 30L -> "THIS MONTH"
        else -> "OLDER"
    }
}
