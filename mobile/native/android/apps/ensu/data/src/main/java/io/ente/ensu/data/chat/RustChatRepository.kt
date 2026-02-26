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
import io.ente.labs.ensu_db.AttachmentKind
import io.ente.labs.ensu_db.AttachmentMeta
import io.ente.labs.ensu_db.DbException
import io.ente.labs.ensu_db.EnsuDb
import java.io.File

class RustChatRepository(
    context: Context,
    private val credentialStore: CredentialStore
) : ChatRepository {

    private val filePaths = FilePathManager(context)
    private val attachmentsDir = filePaths.attachmentsDir
    private val offlineDbFile = filePaths.mainDbFile
    private val onlineDbFile = filePaths.onlineDbFile
    private val syncDbFile = filePaths.syncDbFile
    private var offlineDbKey = credentialStore.getOrCreateChatDbKey()
    private var onlineDbKey: ByteArray? = null
    private var usingOnlineDb = false
    private var db: EnsuDb = openDb(offlineDbFile, offlineDbKey)

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
                    io.ente.labs.ensu_db.Sender.SELF_USER -> MessageAuthor.User
                    io.ente.labs.ensu_db.Sender.OTHER -> MessageAuthor.Assistant
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
            sender = if (author == MessageAuthor.User) io.ente.labs.ensu_db.Sender.SELF_USER else io.ente.labs.ensu_db.Sender.OTHER,
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

    override fun enterOnlineMode(chatKey: ByteArray) {
        onlineDbKey = chatKey
        usingOnlineDb = true
        db = openDb(onlineDbFile, chatKey)
    }

    override fun exitOnlineMode() {
        usingOnlineDb = false
        onlineDbKey = null
        offlineDbKey = credentialStore.getOrCreateChatDbKey()
        db = openDb(offlineDbFile, offlineDbKey)
    }

    override fun deleteAllData() {
        offlineDbFile.delete()
        onlineDbFile.delete()
        syncDbFile.delete()
        filePaths.encryptedAttachmentsDir.deleteRecursively()
        filePaths.syncMetaDir.deleteRecursively()
        filePaths.attachmentsDir.deleteRecursively()
        filePaths.plaintextAttachmentsDir.deleteRecursively()

        filePaths.encryptedAttachmentsDir.mkdirs()
        filePaths.syncMetaDir.mkdirs()
        filePaths.attachmentsDir.mkdirs()
        filePaths.plaintextAttachmentsDir.mkdirs()

        usingOnlineDb = false
        onlineDbKey = null
        offlineDbKey = credentialStore.getOrCreateChatDbKey()
        db = openDb(offlineDbFile, offlineDbKey)
    }

    private fun openDb(dbFile: File, key: ByteArray): EnsuDb {
        return EnsuDb.open(
            dbFile.absolutePath,
            syncDbFile.absolutePath,
            key
        )
    }

    private fun <T> withDbRecovery(block: () -> T): T {
        val targetDbFile = if (usingOnlineDb) onlineDbFile else offlineDbFile
        if (!syncDbFile.exists() || !targetDbFile.exists()) {
            reopenDb(targetDbFile)
        }
        return try {
            block()
        } catch (error: DbException) {
            if (isReadonlyDbError(error)) {
                reopenDb(targetDbFile)
                return block()
            }
            if (shouldResetDb(error)) {
                resetDb()
                return block()
            }
            throw error
        }
    }

    private fun reopenDb(targetDbFile: File) {
        targetDbFile.parentFile?.mkdirs()
        syncDbFile.parentFile?.mkdirs()
        targetDbFile.setWritable(true)
        syncDbFile.setWritable(true)
        db = openDb(targetDbFile, currentDbKey())
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

    private fun currentDbKey(): ByteArray {
        return if (usingOnlineDb) {
            onlineDbKey ?: throw IllegalStateException("Missing online DB key")
        } else {
            offlineDbKey
        }
    }

    private fun resetDb() {
        val targetDbFile = if (usingOnlineDb) onlineDbFile else offlineDbFile
        targetDbFile.delete()
        syncDbFile.delete()
        db = openDb(targetDbFile, currentDbKey())
    }
}
