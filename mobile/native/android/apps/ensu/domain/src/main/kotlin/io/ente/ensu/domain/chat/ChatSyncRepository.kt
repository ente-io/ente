package io.ente.ensu.domain.chat

interface ChatSyncRepository {
    suspend fun sync()
    suspend fun downloadAttachment(attachmentId: String, sessionId: String): Boolean
}
