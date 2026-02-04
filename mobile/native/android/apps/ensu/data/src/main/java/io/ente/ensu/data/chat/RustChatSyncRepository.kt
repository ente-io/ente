package io.ente.ensu.data.chat

import android.content.Context
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.network.NetworkConfiguration
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.data.storage.FilePathManager
import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.ensu.domain.model.MigrationConfig as DomainMigrationConfig
import io.ente.ensu.domain.model.MigrationPriority as DomainMigrationPriority
import io.ente.ensu.domain.model.MigrationProgress as DomainMigrationProgress
import io.ente.ensu.domain.model.MigrationState as DomainMigrationState
import io.ente.labs.llmchat_sync.LlmChatSync
import io.ente.labs.llmchat_sync.MigrationConfig as RustMigrationConfig
import io.ente.labs.llmchat_sync.MigrationPriority as RustMigrationPriority
import io.ente.labs.llmchat_sync.MigrationProgress as RustMigrationProgress
import io.ente.labs.llmchat_sync.MigrationProgressCallback
import io.ente.labs.llmchat_sync.MigrationState as RustMigrationState
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
    private var chatKey: ByteArray? = null

    override suspend fun sync() {
        withContext(Dispatchers.IO) {
            try {
                ensureSyncEngine().sync(buildAuth())
            } catch (err: Throwable) {
                if (shouldResetSync(err)) {
                    resetSyncStateInternal()
                    try {
                        ensureSyncEngine().sync(buildAuth())
                        return@withContext
                    } catch (retryErr: Throwable) {
                        throw IllegalStateException(syncErrorMessage(retryErr), retryErr)
                    }
                }
                throw IllegalStateException(syncErrorMessage(err), err)
            }
        }
    }

    override suspend fun syncWithProgress(
        config: DomainMigrationConfig,
        onProgress: (DomainMigrationProgress) -> Unit
    ) {
        withContext(Dispatchers.IO) {
            val callback = object : MigrationProgressCallback {
                override fun onProgress(progress: RustMigrationProgress) {
                    onProgress(progress.toDomain())
                }
            }
            ensureSyncEngine().syncWithProgress(buildAuth(), config.toRust(), callback)
        }
    }

    override suspend fun checkMigrationStatusLocal(): DomainMigrationState? {
        return withContext(Dispatchers.IO) {
            runCatching { syncEngine?.checkMigrationStatusLocal() }
                .getOrNull()
                ?.toDomain()
        }
    }

    override suspend fun checkMigrationStatus(): DomainMigrationState {
        return withContext(Dispatchers.IO) {
            ensureSyncEngine().checkMigrationStatus(buildAuth()).toDomain()
        }
    }

    override suspend fun downloadAttachment(attachmentId: String, sessionId: String): Boolean {
        return withContext(Dispatchers.IO) {
            ensureSyncEngine().downloadAttachment(attachmentId, sessionId, buildAuth())
        }
    }

    override suspend fun prepareOnlineDb(): ByteArray {
        return withContext(Dispatchers.IO) {
            resetSyncStateInternal()
            val auth = buildAuth()
            val key = io.ente.labs.llmchat_sync.fetchChatKey(auth, filePaths.syncDbFile.absolutePath)
            chatKey = key
            val engine = buildSyncEngine(key).also { syncEngine = it }
            val offlineKey = credentialStore.getOrCreateChatDbKey()
            engine.seedFromOffline(filePaths.mainDbFile.absolutePath, offlineKey)
            key
        }
    }

    override suspend fun resetSyncState() {
        withContext(Dispatchers.IO) {
            resetSyncStateInternal()
        }
    }

    private suspend fun ensureSyncEngine(): LlmChatSync {
        return syncEngine ?: run {
            val key = chatKey ?: prepareOnlineDb()
            buildSyncEngine(key).also { syncEngine = it }
        }
    }

    private fun buildSyncEngine(dbKey: ByteArray): LlmChatSync {
        return LlmChatSync.open(
            mainDbPath = filePaths.onlineDbFile.absolutePath,
            attachmentsDbPath = filePaths.syncDbFile.absolutePath,
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

    private fun resetSyncStateInternal() {
        runCatching { syncEngine?.resetSyncState() }
        syncEngine = null
        chatKey = null
        filePaths.onlineDbFile.delete()
        filePaths.syncDbFile.delete()
        filePaths.syncMetaDir.deleteRecursively()
        filePaths.encryptedAttachmentsDir.deleteRecursively()
        filePaths.encryptedAttachmentsDir.mkdirs()
        filePaths.syncMetaDir.mkdirs()
    }

    private fun syncErrorMessage(error: Throwable): String {
        val syncMessage = generateSequence(error) { it.cause }
            .filterIsInstance<SyncException.Message>()
            .firstOrNull()
        if (syncMessage != null) {
            return syncMessage.v1
        }

        val inProgress = generateSequence(error) { it.cause }
            .filterIsInstance<SyncException.SyncInProgress>()
            .firstOrNull()
        if (inProgress != null) {
            return "Sync already in progress"
        }

        val rootCause = generateSequence(error) { it.cause }.lastOrNull() ?: error
        return rootCause.message ?: error.message ?: rootCause.toString()
    }

    private fun DomainMigrationConfig.toRust(): RustMigrationConfig {
        return RustMigrationConfig(
            batchSize = batchSize,
            priority = when (priority) {
                DomainMigrationPriority.RECENT_FIRST -> RustMigrationPriority.RECENT_FIRST
                DomainMigrationPriority.OLDEST_FIRST -> RustMigrationPriority.OLDEST_FIRST
            }
        )
    }

    private fun RustMigrationState.toDomain(): DomainMigrationState {
        return when (this) {
            RustMigrationState.NOT_NEEDED -> DomainMigrationState.NOT_NEEDED
            RustMigrationState.IN_PROGRESS -> DomainMigrationState.IN_PROGRESS
            RustMigrationState.COMPLETE -> DomainMigrationState.COMPLETE
            RustMigrationState.FAILED -> DomainMigrationState.FAILED
        }
    }

    private fun RustMigrationProgress.toDomain(): DomainMigrationProgress {
        return DomainMigrationProgress(
            state = state.toDomain(),
            processed = processed,
            remaining = remaining,
            total = total
        )
    }
}
