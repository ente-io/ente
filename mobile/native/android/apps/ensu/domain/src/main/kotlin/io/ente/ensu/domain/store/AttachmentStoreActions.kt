package io.ente.ensu.domain.store

import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentDownloadItem
import io.ente.ensu.domain.model.AttachmentDownloadStatus
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.state.AppState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedDeque

internal class AttachmentStoreActions(
    private val state: MutableStateFlow<AppState>,
    private val chatSyncRepository: ChatSyncRepository?,
    private val messageStore: MutableMap<String, MutableList<ChatMessage>>
) {
    private val attachmentDownloads = ConcurrentHashMap<String, AttachmentDownloadItem>()
    private val attachmentDownloadQueue = ConcurrentLinkedDeque<String>()
    private val attachmentDownloadActive = ConcurrentHashMap<String, Job>()
    private val maxAttachmentDownloadConcurrency = 2
    private var scope: CoroutineScope? = null

    fun setScope(scope: CoroutineScope) {
        this.scope = scope
    }

    fun setAttachmentProcessing(isProcessing: Boolean) {
        state.update { appState ->
            appState.copy(chat = appState.chat.copy(isProcessingAttachments = isProcessing))
        }
    }

    fun addAttachment(attachment: Attachment) {
        if (state.value.chat.isGenerating ||
            state.value.chat.isDownloading ||
            state.value.chat.isAttachmentDownloadBlocked
        ) return

        state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    attachments = appState.chat.attachments + attachment,
                    isProcessingAttachments = false
                )
            )
        }
    }

    fun removeAttachment(attachment: Attachment) {
        state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    attachments = appState.chat.attachments.filterNot { it.id == attachment.id }
                )
            )
        }
    }

    fun cancelAttachmentDownload(attachmentId: String) {
        attachmentDownloadActive[attachmentId]?.cancel()
        attachmentDownloadActive.remove(attachmentId)
        attachmentDownloadQueue.removeIf { it == attachmentId }
        attachmentDownloads[attachmentId]?.let { item ->
            attachmentDownloads[attachmentId] = item.copy(status = AttachmentDownloadStatus.Canceled)
        }
        updateAttachmentDownloadState()
        startNextAttachmentDownloads()
    }

    fun ensureAttachmentsAvailable(sessionId: String) {
        val missing = missingAttachments(sessionId)
        if (missing.isEmpty()) {
            updateAttachmentDownloadState()
            return
        }
        queueAttachmentDownloads(missing)
        updateAttachmentDownloadState()
    }

    fun missingAttachments(sessionId: String): List<AttachmentDownloadItem> {
        val messages = messageStore[sessionId].orEmpty()
        if (messages.isEmpty()) return emptyList()
        val seen = mutableSetOf<String>()
        val missing = mutableListOf<AttachmentDownloadItem>()

        for (message in messages) {
            for (attachment in message.attachments) {
                if (!seen.add(attachment.id)) continue
                val path = attachment.localPath
                if (path != null && File(path).exists()) {
                    attachmentDownloadActive[attachment.id]?.cancel()
                    attachmentDownloadActive.remove(attachment.id)
                    attachmentDownloadQueue.removeIf { it == attachment.id }
                    attachmentDownloads.remove(attachment.id)
                    continue
                }
                val existing = attachmentDownloads[attachment.id]
                val status = existing?.status ?: AttachmentDownloadStatus.Queued
                missing.add(
                    AttachmentDownloadItem(
                        id = attachment.id,
                        sessionId = sessionId,
                        name = attachment.name,
                        sizeBytes = attachment.sizeBytes,
                        status = status
                    )
                )
            }
        }

        return missing
    }

    fun purgeAttachmentDownloads(sessionId: String) {
        val ids = attachmentDownloads.values.filter { it.sessionId == sessionId }.map { it.id }
        ids.forEach { id ->
            attachmentDownloadActive[id]?.cancel()
            attachmentDownloadActive.remove(id)
            attachmentDownloadQueue.removeIf { it == id }
            attachmentDownloads.remove(id)
        }
        updateAttachmentDownloadState()
    }

    fun refreshAttachmentDownloadState() {
        updateAttachmentDownloadState()
    }

    private fun queueAttachmentDownloads(items: List<AttachmentDownloadItem>) {
        items.forEach { item ->
            val existing = attachmentDownloads[item.id]
            val updated = if (existing == null ||
                existing.status == AttachmentDownloadStatus.Failed ||
                existing.status == AttachmentDownloadStatus.Canceled
            ) {
                item
            } else {
                existing
            }
            attachmentDownloads[item.id] = updated
            if (updated.status != AttachmentDownloadStatus.Completed &&
                updated.status != AttachmentDownloadStatus.Canceled &&
                attachmentDownloadActive[item.id] == null &&
                !attachmentDownloadQueue.contains(item.id)
            ) {
                attachmentDownloadQueue.addLast(item.id)
            }
        }
        startNextAttachmentDownloads()
    }

    private fun startNextAttachmentDownloads() {
        val scope = scope ?: return
        while (attachmentDownloadActive.size < maxAttachmentDownloadConcurrency && attachmentDownloadQueue.isNotEmpty()) {
            val id = attachmentDownloadQueue.pollFirst() ?: continue
            if (attachmentDownloadActive.containsKey(id)) {
                continue
            }
            val item = attachmentDownloads[id] ?: continue
            if (item.status == AttachmentDownloadStatus.Completed || item.status == AttachmentDownloadStatus.Canceled) {
                continue
            }
            attachmentDownloads[id] = item.copy(status = AttachmentDownloadStatus.Downloading)
            updateAttachmentDownloadState()

            val job = scope.launch(Dispatchers.IO) {
                val result = runCatching {
                    chatSyncRepository?.downloadAttachment(id, item.sessionId)
                        ?: throw IllegalStateException("Sync unavailable")
                }
                val status = if (result.isSuccess) {
                    AttachmentDownloadStatus.Completed
                } else {
                    AttachmentDownloadStatus.Failed
                }
                withContext(Dispatchers.Main) {
                    attachmentDownloads[id]?.let { current ->
                        if (current.status != AttachmentDownloadStatus.Canceled) {
                            attachmentDownloads[id] = current.copy(status = status)
                        }
                    }
                    attachmentDownloadActive.remove(id)
                    updateAttachmentDownloadState()
                    startNextAttachmentDownloads()
                }
            }
            attachmentDownloadActive[id] = job
        }
    }

    private fun updateAttachmentDownloadState() {
        val currentSessionId = state.value.chat.currentSessionId
        val missing = currentSessionId?.let { missingAttachments(it) }.orEmpty()
        val items = attachmentDownloads.values.sortedBy { it.name }
        val active = items.filter { it.status != AttachmentDownloadStatus.Canceled }
        val total = active.size
        val completed = active.count { it.status == AttachmentDownloadStatus.Completed }
        val hasPending = active.any {
            it.status == AttachmentDownloadStatus.Queued ||
                it.status == AttachmentDownloadStatus.Downloading ||
                it.status == AttachmentDownloadStatus.Failed
        }
        val progress = if (total > 0 && hasPending) (completed * 100 / total) else null
        state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    attachmentDownloads = items,
                    attachmentDownloadProgress = progress,
                    isAttachmentDownloadBlocked = missing.isNotEmpty()
                )
            )
        }
    }
}
