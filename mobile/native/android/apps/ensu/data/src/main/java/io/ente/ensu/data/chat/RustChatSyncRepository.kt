package io.ente.ensu.data.chat

import android.content.Context
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.network.NetworkConfiguration
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.data.storage.FilePathManager
import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.labs.llmchat_sync.LlmChatSync
import io.ente.labs.llmchat_sync.SyncAuth
import io.ente.labs.llmchat_sync.SyncException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext

class RustChatSyncRepository(
    private val context: Context,
    private val credentialStore: CredentialStore,
    private val endpointPreferences: EndpointPreferencesDataStore
) : ChatSyncRepository {

    private val filePaths = FilePathManager(context)
    private var syncEngine: LlmChatSync? = null

    override suspend fun sync() {
        withContext(Dispatchers.IO) {
            try {
                syncEngine().sync(buildAuth())
            } catch (err: Throwable) {
                if (shouldResetSync(err)) {
                    resetSyncState()
                    try {
                        syncEngine().sync(buildAuth())
                        return@withContext
                    } catch (retryErr: Throwable) {
                        throw IllegalStateException(syncErrorMessage(retryErr), retryErr)
                    }
                }
                throw IllegalStateException(syncErrorMessage(err), err)
            }
        }
    }

    override suspend fun downloadAttachment(attachmentId: String, sessionId: String): Boolean {
        return withContext(Dispatchers.IO) {
            syncEngine().downloadAttachment(attachmentId, sessionId, buildAuth())
        }
    }

    private fun syncEngine(): LlmChatSync {
        return syncEngine ?: buildSyncEngine().also { syncEngine = it }
    }

    private fun buildSyncEngine(): LlmChatSync {
        val dbKey = credentialStore.getOrCreateChatDbKey()
        return LlmChatSync.open(
            mainDbPath = filePaths.mainDbFile.absolutePath,
            attachmentsDbPath = filePaths.attachmentsDbFile.absolutePath,
            dbKey = dbKey,
            attachmentsDir = filePaths.encryptedAttachmentsDir.absolutePath,
            metaDir = filePaths.syncMetaDir.absolutePath,
            plaintextDir = filePaths.plaintextAttachmentsDir.absolutePath
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

    private fun shouldResetSync(error: Throwable): Boolean {
        val message = syncErrorMessage(error)
        return ChatRecovery.shouldResetFromMessage(message)
    }

    private fun resetSyncState() {
        runCatching { filePaths.syncMetaDir.deleteRecursively() }
        runCatching { filePaths.syncMetaDir.mkdirs() }
        syncEngine = null
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
