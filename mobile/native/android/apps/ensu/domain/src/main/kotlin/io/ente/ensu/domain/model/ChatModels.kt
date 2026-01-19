package io.ente.ensu.domain.model

import java.util.UUID

enum class MessageAuthor {
    User,
    Assistant
}

data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val sessionId: String,
    val author: MessageAuthor,
    val text: String,
    val timestampMillis: Long,
    val attachments: List<Attachment> = emptyList(),
    val isInterrupted: Boolean = false,
    val tokensPerSecond: Double? = null,
    val branchCount: Int = 1
)

data class ChatSession(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val lastMessagePreview: String? = null,
    val updatedAtMillis: Long
)

enum class AttachmentType {
    Image,
    Document
}

data class Attachment(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val sizeBytes: Long,
    val type: AttachmentType,
    val isUploading: Boolean = false
)
