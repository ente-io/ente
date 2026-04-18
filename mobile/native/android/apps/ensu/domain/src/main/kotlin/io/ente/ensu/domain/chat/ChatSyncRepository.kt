package io.ente.ensu.domain.chat

import io.ente.ensu.domain.model.MigrationConfig
import io.ente.ensu.domain.model.MigrationProgress
import io.ente.ensu.domain.model.MigrationState

interface ChatSyncRepository {
    suspend fun sync()
    suspend fun syncWithProgress(config: MigrationConfig, onProgress: (MigrationProgress) -> Unit)
    suspend fun checkMigrationStatusLocal(): MigrationState?
    suspend fun checkMigrationStatus(): MigrationState
    suspend fun downloadAttachment(attachmentId: String, sessionId: String): Boolean
    suspend fun prepareOnlineDb(): ByteArray
    suspend fun resetSyncState()
}
