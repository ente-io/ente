package io.ente.ensu.data.chat

import android.content.Context
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.network.NetworkConfiguration
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.labs.llmchat_sync.LlmChatSync
import io.ente.labs.llmchat_sync.SyncAuth
import io.ente.labs.llmchat_sync.SyncException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import java.io.File

class RustChatSyncRepository(
    private val context: Context,
    private val credentialStore: CredentialStore,
    private val endpointPreferences: EndpointPreferencesDataStore
) : ChatSyncRepository {

    private val syncEngine: LlmChatSync by lazy { buildSyncEngine() }

    override suspend fun sync() {
        withContext(Dispatchers.IO) {
            try {
                syncEngine.sync(buildAuth())
            } catch (err: Throwable) {
                throw IllegalStateException(syncErrorMessage(err), err)
            }
        }
    }

    override suspend fun downloadAttachment(attachmentId: String, sessionId: String): Boolean {
        return withContext(Dispatchers.IO) {
            syncEngine.downloadAttachment(attachmentId, sessionId, buildAuth())
        }
    }

    private fun buildSyncEngine(): LlmChatSync {
        val baseDir = File(context.filesDir, "llmchat")
        if (!baseDir.exists()) baseDir.mkdirs()

        val encryptedAttachmentsDir = File(baseDir, "chat_attachments_encrypted")
        if (!encryptedAttachmentsDir.exists()) encryptedAttachmentsDir.mkdirs()

        val metaDir = File(baseDir, "sync_meta")
        if (!metaDir.exists()) metaDir.mkdirs()

        val mainDb = File(context.filesDir, "llmchat.db").absolutePath
        val attachmentsDb = File(context.filesDir, "llmchat_attachments.db").absolutePath
        val dbKey = credentialStore.getOrCreateChatDbKey()
        val plaintextDir = File(context.filesDir, "attachments")
        if (!plaintextDir.exists()) plaintextDir.mkdirs()

        return LlmChatSync.open(
            mainDbPath = mainDb,
            attachmentsDbPath = attachmentsDb,
            dbKey = dbKey,
            attachmentsDir = encryptedAttachmentsDir.absolutePath,
            metaDir = metaDir.absolutePath,
            plaintextDir = plaintextDir.absolutePath
        )
    }

    private suspend fun buildAuth(): SyncAuth {
        val endpoint = endpointPreferences.endpointFlow.first()
        val baseUrl = endpoint ?: NetworkConfiguration.default.apiEndpoint.toString()
        val token = credentialStore.getToken()?.let(::normalizeToken)
            ?: throw IllegalStateException("Missing auth token")
        val masterKey = credentialStore.getMasterKey()
            ?: throw IllegalStateException("Missing master key")

        val clientVersion = runCatching {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName
        }.getOrNull()

        return SyncAuth(
            baseUrl = baseUrl,
            authToken = token,
            masterKey = masterKey,
            userAgent = "EnteNative-Android",
            clientPackage = context.packageName,
            clientVersion = clientVersion
        )
    }

    private fun normalizeToken(token: String): String {
        val remainder = token.length % 4
        return if (remainder == 0) token else token + "=".repeat(4 - remainder)
    }

    private fun syncErrorMessage(error: Throwable): String {
        val syncMessage = generateSequence(error) { it.cause }
            .filterIsInstance<SyncException.Message>()
            .firstOrNull()
        if (syncMessage != null) {
            return syncMessage.v1
        }

        val rootCause = generateSequence(error) { it.cause }.lastOrNull() ?: error
        return rootCause.message ?: error.message ?: rootCause.toString()
    }
}
