package io.ente.ensu.chat

import android.content.Context
import io.ente.ensu.storage.CredentialStore
import io.ente.ensu.storage.FilePathManager
import io.ente.ensu.chat.Attachment
import io.ente.ensu.chat.AttachmentType
import io.ente.ensu.chat.ChatMessage
import io.ente.ensu.chat.ChatSession
import io.ente.ensu.chat.MessageAuthor
import io.ente.ensu.chat.sessionTitleFromText
import io.ente.ensu.bindings.AttachmentKind
import io.ente.ensu.bindings.AttachmentMeta
import io.ente.ensu.bindings.Sender
import io.ente.ensu.bindings.EnsuDb
import io.ente.ensu.bindings.DbException
import java.io.File

class RustChatRepository(
    context: Context,
    private val credentialStore: CredentialStore
) {

    private val filePaths = FilePathManager(context)
    private val attachmentsDir = filePaths.attachmentsDir
    private val dbFile = filePaths.mainDbFile
    private val attachmentsDbFile = filePaths.attachmentsDbFile
    private var dbKey = credentialStore.getOrCreateChatDbKey()
    private var db: EnsuDb = openDb(dbFile, dbKey)

    fun listSessions(): List<ChatSession> = withDbRecovery {
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

    fun createSession(title: String): ChatSession = withDbRecovery {
        val session = db.createSession(title)
        ChatSession(
            id = session.uuid,
            title = session.title,
            lastMessagePreview = null,
            updatedAtMillis = session.updatedAtUs / 1000
        )
    }

    fun deleteSession(sessionId: String) = withDbRecovery {
        db.deleteSession(sessionId)
    }

    fun getMessages(sessionId: String): List<ChatMessage> = withDbRecovery {
        db.getMessages(sessionId).map { message ->
            ChatMessage(
                id = message.uuid,
                sessionId = message.sessionUuid,
                parentId = message.parentMessageUuid,
                author = when (message.sender) {
                    Sender.SELF_USER -> MessageAuthor.User
                    Sender.OTHER -> MessageAuthor.Assistant
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

    fun insertMessage(
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
            sender = if (author == MessageAuthor.User) {
                Sender.SELF_USER
            } else {
                Sender.OTHER
            },
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

    fun updateMessageText(messageId: String, text: String) = withDbRecovery {
        db.updateMessageText(messageId, text)
    }

    fun updateSessionTitle(sessionId: String, title: String) = withDbRecovery {
        db.updateSessionTitle(sessionId, title)
    }

    fun deleteAllData() {
        // Full reset removes current storage plus legacy sync leftovers.
        dbFile.delete()
        attachmentsDbFile.delete()
        filePaths.legacyOnlineDbFile.delete()
        filePaths.legacySyncDir.deleteRecursively()
        filePaths.attachmentsDir.deleteRecursively()

        filePaths.attachmentsDir.mkdirs()

        dbKey = credentialStore.getOrCreateChatDbKey()
        db = openDb(dbFile, dbKey)
    }

    private fun openDb(dbFile: File, key: ByteArray): EnsuDb {
        return EnsuDb.open(
            dbFile.absolutePath,
            attachmentsDbFile.absolutePath,
            key
        )
    }

    private fun <T> withDbRecovery(block: () -> T): T {
        if (!attachmentsDbFile.exists() || !dbFile.exists()) {
            reopenDb()
        }
        return try {
            block()
        } catch (error: DbException) {
            if (isReadonlyDbError(error)) {
                reopenDb()
                return block()
            }
            if (shouldResetDb(error)) {
                resetDb()
                return block()
            }
            throw error
        }
    }

    private fun reopenDb() {
        dbFile.parentFile?.mkdirs()
        attachmentsDbFile.parentFile?.mkdirs()
        dbFile.setWritable(true)
        attachmentsDbFile.setWritable(true)
        db = openDb(dbFile, dbKey)
    }

    private fun shouldResetDb(error: DbException): Boolean {
        val message = when (error) {
            is DbException.Message -> error.v1
            else -> error.message.orEmpty()
        }
        return ChatRecovery.shouldResetFromMessage(message)
    }

    private fun isReadonlyDbError(error: DbException): Boolean {
        val message = when (error) {
            is DbException.Message -> error.v1
            else -> error.message.orEmpty()
        }
        return message.contains("readonly database", ignoreCase = true)
    }

    private fun resetDb() {
        dbFile.delete()
        attachmentsDbFile.delete()
        db = openDb(dbFile, dbKey)
    }
}
