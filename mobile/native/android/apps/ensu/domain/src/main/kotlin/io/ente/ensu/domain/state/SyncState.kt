package io.ente.ensu.domain.state

sealed class SyncState {
    data object Idle : SyncState()
    data object Syncing : SyncState()
    data class Migrating(val processed: Long, val total: Long) : SyncState()
    data class Error(val message: String) : SyncState()
}
