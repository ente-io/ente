package io.ente.ensu.domain.chat

import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession
import io.ente.ensu.domain.model.MessageAuthor

interface ChatRepository {
    fun listSessions(): List<ChatSession>
    fun createSession(title: String): ChatSession
    fun deleteSession(sessionId: String)

    fun getMessages(sessionId: String): List<ChatMessage>

    fun insertMessage(
        sessionId: String,
        parentId: String?,
        author: MessageAuthor,
        text: String,
        attachments: List<Attachment>
    ): ChatMessage

    fun updateMessageText(messageId: String, text: String)
}
