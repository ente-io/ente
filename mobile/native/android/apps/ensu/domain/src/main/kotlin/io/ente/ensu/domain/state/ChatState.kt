package io.ente.ensu.domain.state

import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession


data class ChatState(
    val sessions: List<ChatSession> = emptyList(),
    val currentSessionId: String? = null,
    val messages: List<ChatMessage> = emptyList(),
    val streamingResponse: String = "",
    val streamingParentId: String? = null,
    val isGenerating: Boolean = false,
    val isDownloading: Boolean = false,
    val downloadPercent: Int? = null,
    val downloadStatus: String? = null,
    val messageText: String = "",
    val attachments: List<Attachment> = emptyList(),
    val editingMessageId: String? = null,
    val branchSelections: Map<String, Int> = emptyMap(),
    val isProcessingAttachments: Boolean = false,
    val attachmentDownloads: List<io.ente.ensu.domain.model.AttachmentDownloadItem> = emptyList(),
    val attachmentDownloadProgress: Int? = null,
    val isAttachmentDownloadBlocked: Boolean = false
)
