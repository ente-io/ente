package io.ente.ensu.chat

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import io.ente.ensu.AppStore
import io.ente.ensu.bindings.KnowledgeDatasetConfig
import io.ente.ensu.components.CompactButton
import io.ente.ensu.components.KnowledgeCard
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.device.isChatSupported
import io.ente.ensu.knowledge.KnowledgeState
import io.ente.ensu.notes.NotesStatus
import io.ente.ensu.settings.KnowledgePackCard
import io.ente.ensu.settings.PackAttributionDialog

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ChatSourcesSheet(
    visible: Boolean,
    chatState: ChatState,
    knowledgeState: KnowledgeState,
    store: AppStore,
    onDismiss: () -> Unit,
) {
    val notesState by store.notesStore.state.collectAsState()
    var attribution by remember { mutableStateOf<KnowledgeDatasetConfig?>(null) }
    var pendingFolderTarget by rememberSaveable { mutableStateOf<String?>(null) }
    // Keep the launcher registered after the sheet closes, until the system picker returns.
    val folderPicker =
        rememberLauncherForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
            store.setPickerPending(false)
            val target = pendingFolderTarget
            pendingFolderTarget = null
            if (uri != null && target != null) store.addNotesFolderForChat(uri, target)
        }
    if (!visible) return

    val controlsEnabled =
        chatState.sourceSelectionReady &&
            !chatState.isGenerating &&
            chatState.preparationStatus == null &&
            !chatState.isDownloading
    val supported = chatState.deviceCapability.isChatSupported()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = EnsuColor.backgroundBase(),
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxWidth().heightIn(max = 640.dp),
            contentPadding =
                PaddingValues(
                    horizontal = EnsuSpacing.pageHorizontal.dp,
                    vertical = EnsuSpacing.md.dp,
                ),
            verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp),
        ) {
            item {
                Text("Sources", style = EnsuTypography.h3Bold, color = EnsuColor.textPrimary())
                Text(
                    "Choose what Ensu can use in this chat. Turning a source off does not remove information already in the conversation.",
                    style = EnsuTypography.small,
                    color = EnsuColor.textMuted(),
                )
            }
            if (!controlsEnabled) {
                item {
                    val inventoryLoading =
                        knowledgeState.inventoryLoading || notesState.inventoryLoading
                    val inventoryFailed =
                        !inventoryLoading &&
                            (!knowledgeState.inventoryReady || !notesState.inventoryReady)
                    Text(
                        when {
                            inventoryFailed ->
                                "Could not load all sources. Your saved choices have been kept."
                            !chatState.sourceSelectionReady -> "Loading sources…"
                            else -> "You can change sources after the response finishes."
                        },
                        style = EnsuTypography.small,
                        color = EnsuColor.textMuted(),
                    )
                    if (inventoryFailed) {
                        CompactButton(
                            label = "Retry loading sources",
                            onClick = store::retrySourceInventory,
                            enabled = !chatState.isGenerating,
                        )
                    }
                }
            }
            item {
                Text("Ensu Packs", style = EnsuTypography.large, color = EnsuColor.textPrimary())
            }
            if (knowledgeState.packs.isEmpty()) {
                item {
                    Text(
                        "No Ensu Packs available.",
                        style = EnsuTypography.small,
                        color = EnsuColor.textMuted(),
                    )
                }
            }
            items(knowledgeState.packs.values.toList(), key = { "pack-${it.config.stableId}" }) {
                pack ->
                KnowledgePackCard(
                    pack = pack,
                    packDownloadsAllowed = supported,
                    selected = chatState.sourceSelection.isPackEnabled(pack.config.stableId),
                    controlsEnabled = controlsEnabled,
                    onDownloadOrUpdate = {
                        store.downloadKnowledgePackForChat(
                            pack.config.stableId,
                            store.sourceSelectionTarget(),
                        )
                    },
                    onCancel = { store.cancelKnowledgePackDownload(pack.config.stableId) },
                    onSetEnabled = { store.setKnowledgePackEnabled(pack.config.stableId, it) },
                    onOpenAttribution = { attribution = pack.config },
                )
            }
            item {
                Text("Your Notes", style = EnsuTypography.large, color = EnsuColor.textPrimary())
            }
            items(notesState.collections, key = { "folder-${it.id}" }) { folder ->
                KnowledgeCard(spacing = EnsuSpacing.sm.dp) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                folder.label,
                                style = EnsuTypography.large,
                                color = EnsuColor.textPrimary(),
                            )
                            Text(
                                when (folder.status) {
                                    NotesStatus.Pending -> "Preparing notes…"
                                    NotesStatus.Indexing -> "Indexing notes…"
                                    NotesStatus.Updating -> "Updating notes…"
                                    NotesStatus.Unavailable -> "Folder unavailable"
                                    NotesStatus.Error -> "Could not index folder"
                                    NotesStatus.Ready -> "${folder.documentCount} notes indexed"
                                },
                                style = EnsuTypography.mini,
                                color = EnsuColor.textMuted(),
                            )
                        }
                        Switch(
                            checked = chatState.sourceSelection.isFolderEnabled(folder.id),
                            onCheckedChange = { store.setNotesFolderEnabled(folder.id, it) },
                            enabled = controlsEnabled,
                            modifier =
                                Modifier.semantics {
                                    contentDescription = "Use ${folder.label} in this chat"
                                },
                        )
                    }
                    folder.progress?.let { progress ->
                        LinearProgressIndicator(
                            progress = { progress.coerceIn(0, 100) / 100f },
                            modifier = Modifier.fillMaxWidth(),
                            color = EnsuColor.action(),
                            trackColor = EnsuColor.border(),
                        )
                    }
                    folder.error?.let { error ->
                        Text(error, style = EnsuTypography.small, color = EnsuColor.error)
                        CompactButton(
                            "Retry",
                            onClick = { store.notesStore.retry(folder.id) },
                            enabled = controlsEnabled,
                        )
                    }
                }
            }
            item {
                CompactButton(
                    "Add notes folder",
                    enabled = controlsEnabled && supported,
                    onClick = {
                        pendingFolderTarget = store.sourceSelectionTarget()
                        store.setPickerPending(true)
                        try {
                            folderPicker.launch(null)
                        } catch (error: Exception) {
                            pendingFolderTarget = null
                            store.setPickerPending(false)
                            throw error
                        }
                    },
                )
            }
            item {
                Text(
                    "Ensu reads and indexes markdown files in the selected folder. Source files are never modified.",
                    style = EnsuTypography.small,
                    color = EnsuColor.textMuted(),
                )
            }
            notesState.error?.let { error ->
                item { Text(error, style = EnsuTypography.small, color = EnsuColor.error) }
            }
        }
    }
    attribution?.let { config -> PackAttributionDialog(config, onDismiss = { attribution = null }) }
}
