package io.ente.ensu.data.chat

import android.content.Context
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.domain.chat.ChatRepository
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession
import io.ente.ensu.domain.model.MessageAuthor
import io.ente.labs.llmchat_db.AttachmentKind
import io.ente.labs.llmchat_db.AttachmentMeta
import io.ente.labs.llmchat_db.LlmChatDb
import java.io.File

class RustChatRepository(
    context: Context,
    credentialStore: CredentialStore
) : ChatRepository {

    private val attachmentsDir = File(context.filesDir, "attachments")
    private val db: LlmChatDb

    init {
        if (!attachmentsDir.exists()) {
            attachmentsDir.mkdirs()
        }

        val mainDb = File(context.filesDir, "llmchat.db").absolutePath
        val attachmentsDb = File(context.filesDir, "llmchat_attachments.db").absolutePath
        val key = credentialStore.getOrCreateChatDbKey()
        db = LlmChatDb.open(mainDb, attachmentsDb, key)
    }

    override fun listSessions(): List<ChatSession> {
        val sessions = db.listSessions()
        return sessions.map { session ->
            val lastMessage = runCatching { db.getMessages(session.uuid) }.getOrNull()?.lastOrNull()?.text
            ChatSession(
                id = session.uuid,
                title = session.title,
                lastMessagePreview = lastMessage,
                updatedAtMillis = session.updatedAtUs / 1000
            )
        }
    }

    override fun createSession(title: String): ChatSession {
        val session = db.createSession(title)
        return ChatSession(
            id = session.uuid,
            title = session.title,
            lastMessagePreview = null,
            updatedAtMillis = session.updatedAtUs / 1000
        )
    }

    override fun deleteSession(sessionId: String) {
        db.deleteSession(sessionId)
    }

    override fun getMessages(sessionId: String): List<ChatMessage> {
        return db.getMessages(sessionId).map { message ->
            ChatMessage(
                id = message.uuid,
                sessionId = message.sessionUuid,
                parentId = message.parentMessageUuid,
                author = when (message.sender) {
                    io.ente.labs.llmchat_db.Sender.SELF_USER -> MessageAuthor.User
                    io.ente.labs.llmchat_db.Sender.OTHER -> MessageAuthor.Assistant
                },
                text = message.text,
                timestampMillis = message.createdAtUs / 1000,
                attachments = message.attachments.map { meta ->
                    Attachment(
                        id = meta.id,
                        name = meta.name,
                        sizeBytes = meta.size,
                        type = when (meta.kind) {
                            AttachmentKind.IMAGE -> AttachmentType.Image
                            AttachmentKind.DOCUMENT -> AttachmentType.Document
                        },
                        localPath = File(attachmentsDir, meta.id).absolutePath,
                        isUploading = false
                    )
                }
            )
        }
    }

    override fun insertMessage(
        sessionId: String,
        parentId: String?,
        author: MessageAuthor,
        text: String,
        attachments: List<Attachment>
    ): ChatMessage {
        val meta = attachments.map { att ->
            AttachmentMeta(
                id = att.id,
                kind = when (att.type) {
                    AttachmentType.Image -> AttachmentKind.IMAGE
                    AttachmentType.Document -> AttachmentKind.DOCUMENT
                },
                size = att.sizeBytes,
                name = att.name
            )
        }

        val message = db.insertMessage(
            sessionUuid = sessionId,
            sender = if (author == MessageAuthor.User) io.ente.labs.llmchat_db.Sender.SELF_USER else io.ente.labs.llmchat_db.Sender.OTHER,
            text = text,
            parentMessageUuid = parentId,
            attachments = meta
        )

        return ChatMessage(
            id = message.uuid,
            sessionId = message.sessionUuid,
            parentId = message.parentMessageUuid,
            author = author,
            text = message.text,
            timestampMillis = message.createdAtUs / 1000,
            attachments = attachments
        )
    }

    override fun updateMessageText(messageId: String, text: String) {
        db.updateMessageText(messageId, text)
    }
}
