package io.ente.ensu

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.ente.ensu.components.EnsuLogo
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.designsystem.HugeIcons
import io.ente.ensu.domain.model.AttachmentDownloadItem
import io.ente.ensu.domain.model.AttachmentDownloadStatus

@Composable
internal fun EnsuTopBar(
    sessionTitle: String?,
    showBrand: Boolean,
    isLoggedIn: Boolean,
    attachmentDownloads: List<AttachmentDownloadItem>,
    attachmentDownloadProgress: Int?,
    modelDownloadStatus: String?,
    modelDownloadPercent: Int?,
    onOpenDrawer: () -> Unit,
    onSignIn: () -> Unit,
    onAttachmentDownloads: () -> Unit
) {
    val titleText = sessionTitle?.takeIf { it.isNotBlank() } ?: "New Chat"

    CenterAlignedTopAppBar(
        title = {
            if (showBrand) {
                EnsuLogo(height = 20.dp)
            } else {
                Text(
                    text = titleText,
                    style = EnsuTypography.h3Bold.copy(fontSize = 20.sp, lineHeight = 24.sp),
                    color = EnsuColor.textPrimary(),
                    maxLines = 1
                )
            }
        },
        navigationIcon = {
            IconButton(onClick = onOpenDrawer) {
                Icon(
                    painter = painterResource(HugeIcons.Menu01Icon),
                    contentDescription = "Menu"
                )
            }
        },
        actions = {
            val isLoading = modelDownloadStatus?.contains("Loading", ignoreCase = true) == true
            val showModelProgress = isLoading

            if (!isLoggedIn) {
                if (showModelProgress) {
                    ModelProgressIndicator(
                        isLoading = isLoading,
                        progressPercent = modelDownloadPercent
                    )
                    Spacer(modifier = Modifier.width(EnsuSpacing.md.dp))
                }
                TextButton(onClick = onSignIn) {
                    Text(text = "Sign In", style = EnsuTypography.small, color = EnsuColor.accent())
                }
            } else {
                val hasPending = attachmentDownloads.any {
                    it.status == AttachmentDownloadStatus.Queued ||
                        it.status == AttachmentDownloadStatus.Downloading ||
                        it.status == AttachmentDownloadStatus.Failed
                }
                if (hasPending) {
                    val active = attachmentDownloads.filter { it.status != AttachmentDownloadStatus.Canceled }
                    val completed = active.count { it.status == AttachmentDownloadStatus.Completed }
                    val total = active.size
                    TextButton(
                        onClick = onAttachmentDownloads,
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                painter = painterResource(HugeIcons.Upload01Icon),
                                contentDescription = "Attachment downloads",
                                tint = EnsuColor.textPrimary()
                            )
                            Text(
                                text = "$completed/$total",
                                style = EnsuTypography.mini,
                                color = EnsuColor.textMuted(),
                                maxLines = 1,
                                softWrap = false,
                                modifier = Modifier.padding(start = 6.dp)
                            )
                        }
                    }
                }
                if (showModelProgress) {
                    if (hasPending) {
                        Spacer(modifier = Modifier.width(EnsuSpacing.md.dp))
                    }
                    ModelProgressIndicator(
                        isLoading = isLoading,
                        progressPercent = modelDownloadPercent,
                        modifier = Modifier.padding(end = EnsuSpacing.sm.dp)
                    )
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

@Composable
private fun ModelProgressIndicator(
    isLoading: Boolean,
    progressPercent: Int?,
    modifier: Modifier = Modifier
) {
    val indicatorModifier = modifier.size(16.dp)
    val clamped = progressPercent?.coerceIn(0, 100)
    if (!isLoading && clamped != null) {
        CircularProgressIndicator(
            progress = { clamped / 100f },
            modifier = indicatorModifier,
            color = EnsuColor.accent(),
            trackColor = EnsuColor.border(),
            strokeWidth = 2.dp
        )
    } else {
        CircularProgressIndicator(
            modifier = indicatorModifier,
            color = EnsuColor.accent(),
            trackColor = EnsuColor.border(),
            strokeWidth = 2.dp
        )
    }
}

@Composable
internal fun SimpleTopBar(title: String, onBack: () -> Unit) {
    TopAppBar(
        title = { Text(text = title, style = EnsuTypography.h3Bold.copy(fontSize = 20.sp, lineHeight = 24.sp)) },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(
                    painter = painterResource(HugeIcons.ArrowLeft01Icon),
                    contentDescription = "Back"
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}

@Composable
internal fun LogsTopBar(onBack: () -> Unit, onShare: () -> Unit) {
    TopAppBar(
        title = { Text(text = "Logs", style = EnsuTypography.h3Bold.copy(fontSize = 20.sp, lineHeight = 24.sp)) },
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(
                    painter = painterResource(HugeIcons.ArrowLeft01Icon),
                    contentDescription = "Back"
                )
            }
        },
        actions = {
            IconButton(onClick = onShare) {
                Icon(
                    painter = painterResource(HugeIcons.Upload01Icon),
                    contentDescription = "Share",
                    modifier = Modifier.size(18.dp)
                )
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = EnsuColor.backgroundBase())
    )
}
