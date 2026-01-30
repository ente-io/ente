package io.ente.ensu.data.chat

import android.content.Context
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.data.storage.FilePathManager
import io.ente.ensu.domain.chat.ChatRepository
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession
import io.ente.ensu.domain.model.MessageAuthor
import io.ente.ensu.domain.model.sessionTitleFromText
import io.ente.labs.llmchat_db.AttachmentKind
import io.ente.labs.llmchat_db.AttachmentMeta
import io.ente.labs.llmchat_db.DbException
import io.ente.labs.llmchat_db.LlmChatDb
import java.io.File

class RustChatRepository(
    context: Context,
    credentialStore: CredentialStore
) : ChatRepository {

    private val filePaths = FilePathManager(context)
    private val attachmentsDir = filePaths.attachmentsDir
    private val mainDbFile = filePaths.mainDbFile
    private val attachmentsDbFile = filePaths.attachmentsDbFile
    private val dbKey = credentialStore.getOrCreateChatDbKey()
    private var db: LlmChatDb = openDb()

    override fun listSessions(): List<ChatSession> = withDbRecovery {
        val sessions = db.listSessions()
        sessions.map { session ->
            val messages = runCatching { db.getMessages(session.uuid) }.getOrNull().orEmpty()
            val firstMessage = messages.firstOrNull()?.text.orEmpty()
            val lastMessage = messages.lastOrNull()?.text
            val isPlaceholder = session.title.isBlank() || session.title.equals("New Chat", ignoreCase = true)
            val seedTitle = if (isPlaceholder) firstMessage else session.title
            ChatSession(
                id = session.uuid,
                title = sessionTitleFromText(seedTitle, fallback = session.title),
                lastMessagePreview = lastMessage,
                updatedAtMillis = session.updatedAtUs / 1000
            )
        }
    }

    override fun createSession(title: String): ChatSession = withDbRecovery {
        val session = db.createSession(title)
        ChatSession(
            id = session.uuid,
            title = session.title,
            lastMessagePreview = null,
            updatedAtMillis = session.updatedAtUs / 1000
        )
    }

    override fun deleteSession(sessionId: String) = withDbRecovery {
        db.deleteSession(sessionId)
    }

    override fun getMessages(sessionId: String): List<ChatMessage> = withDbRecovery {
        db.getMessages(sessionId).map { message ->
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
    ): ChatMessage = withDbRecovery {
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

        ChatMessage(
            id = message.uuid,
            sessionId = message.sessionUuid,
            parentId = message.parentMessageUuid,
            author = author,
            text = message.text,
            timestampMillis = message.createdAtUs / 1000,
            attachments = attachments
        )
    }

    override fun updateMessageText(messageId: String, text: String) = withDbRecovery {
        db.updateMessageText(messageId, text)
    }

    override fun updateSessionTitle(sessionId: String, title: String) = withDbRecovery {
        db.updateSessionTitle(sessionId, title)
    }

    private fun openDb(): LlmChatDb {
        return LlmChatDb.open(
            mainDbFile.absolutePath,
            attachmentsDbFile.absolutePath,
            dbKey
        )
    }

    private fun <T> withDbRecovery(block: () -> T): T {
        return try {
            block()
        } catch (error: DbException) {
            if (shouldResetDb(error)) {
                resetDb()
                block()
            } else {
                throw error
            }
        }
    }

    private fun shouldResetDb(error: DbException): Boolean {
        val message = when (error) {
            is DbException.Message -> error.v1
            else -> error.message.orEmpty()
        }.lowercase()
        return message.contains("stream pull failed") ||
            message.contains("invalid blob") ||
            message.contains("invalid encrypted")
    }

    private fun resetDb() {
        mainDbFile.delete()
        attachmentsDbFile.delete()
        db = openDb()
    }
}
