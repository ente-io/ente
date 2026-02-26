package io.ente.ensu.domain.store

import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.model.MigrationConfig
import io.ente.ensu.domain.model.MigrationPriority
import io.ente.ensu.domain.model.MigrationProgress
import io.ente.ensu.domain.model.MigrationState
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.SyncState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal class SyncStoreActions(
    private val state: MutableStateFlow<AppState>,
    private val chatSyncRepository: ChatSyncRepository?,
    private val logRepository: LogRepository
) {
    private var scope: CoroutineScope? = null
    private var pendingSyncRequested = false
    private var pendingSyncErrorHandler: ((String) -> Unit)? = null
    private var pendingSyncSuccessHandler: (() -> Unit)? = null
    private var reloadSessions: (() -> Unit)? = null
    private val migrationConfig = MigrationConfig(
        batchSize = 25L,
        priority = MigrationPriority.RECENT_FIRST
    )

    fun setScope(scope: CoroutineScope) {
        this.scope = scope
    }

    fun setReloadSessions(loader: () -> Unit) {
        reloadSessions = loader
    }

    fun syncNow(
        onSuccess: (() -> Unit)? = null,
        onError: ((String) -> Unit)? = null
    ) {
        requestSync(onSuccess, onError)
    }

    fun syncAfterLogin() {
        val scope = scope ?: return
        scope.launch {
            val repo = chatSyncRepository ?: return@launch
            try {
                val localStatus: MigrationState? = withContext(Dispatchers.IO) {
                    repo.checkMigrationStatusLocal()
                }
                when (localStatus) {
                    MigrationState.IN_PROGRESS -> performBatchedSync()
                    MigrationState.NOT_NEEDED, MigrationState.COMPLETE -> performSyncInternal()
                    MigrationState.FAILED -> {
                        state.update { it.copy(sync = SyncState.Error("Migration failed")) }
                    }
                    else -> {
                        val status: MigrationState = withContext(Dispatchers.IO) {
                            repo.checkMigrationStatus()
                        }
                        when (status) {
                            MigrationState.IN_PROGRESS -> performBatchedSync()
                            MigrationState.NOT_NEEDED, MigrationState.COMPLETE -> performSyncInternal()
                            MigrationState.FAILED -> {
                                state.update { it.copy(sync = SyncState.Error("Migration failed")) }
                            }
                            else -> {}
                        }
                    }
                }
            } catch (err: Throwable) {
                val message = syncErrorMessage(err)
                logRepository.log(
                    LogLevel.Warning,
                    "Migration status check failed",
                    details = message,
                    tag = "Sync",
                    throwable = err
                )
            }
        }
    }

    fun requestSync(
        onSuccess: (() -> Unit)? = null,
        onError: ((String) -> Unit)? = null
    ) {
        if (state.value.chat.isGenerating) {
            pendingSyncRequested = true
            if (onError != null) {
                pendingSyncErrorHandler = onError
            }
            if (onSuccess != null) {
                pendingSyncSuccessHandler = onSuccess
            }
            return
        }

        val handler = pendingSyncErrorHandler ?: onError
        val successHandler = pendingSyncSuccessHandler ?: onSuccess
        pendingSyncRequested = false
        pendingSyncErrorHandler = null
        pendingSyncSuccessHandler = null
        performSync(handler, successHandler)
    }

    fun syncAfterGeneration() {
        val handler = pendingSyncErrorHandler
        val successHandler = pendingSyncSuccessHandler
        val shouldAutoSync = state.value.auth.isLoggedIn
        if (!pendingSyncRequested && !shouldAutoSync) {
            pendingSyncErrorHandler = null
            pendingSyncSuccessHandler = null
            return
        }
        if (!shouldAutoSync && handler == null && successHandler == null) {
            pendingSyncRequested = false
            pendingSyncErrorHandler = null
            pendingSyncSuccessHandler = null
            return
        }
        pendingSyncRequested = false
        pendingSyncErrorHandler = null
        pendingSyncSuccessHandler = null
        performSync(handler, successHandler)
    }

    private fun performSync(
        onError: ((String) -> Unit)? = null,
        onSuccess: (() -> Unit)? = null
    ) {
        val scope = scope ?: return
        scope.launch {
            performSyncInternal(onError, onSuccess)
        }
    }

    private suspend fun performSyncInternal(
        onError: ((String) -> Unit)? = null,
        onSuccess: (() -> Unit)? = null
    ) {
        val repo = chatSyncRepository ?: return
        if (!state.value.auth.isLoggedIn) {
            state.update { it.copy(sync = SyncState.Idle) }
            return
        }
        try {
            state.update { it.copy(sync = SyncState.Syncing) }
            logRepository.log(LogLevel.Info, "Sync started", tag = "Sync")
            withContext(Dispatchers.IO) {
                repo.sync()
            }
            reloadSessions?.invoke()
            logRepository.log(LogLevel.Info, "Sync success", tag = "Sync")
            state.update { it.copy(sync = SyncState.Idle) }
            if (onSuccess != null) {
                withContext(Dispatchers.Main) {
                    onSuccess()
                }
            }
        } catch (err: Throwable) {
            val message = syncErrorMessage(err)
            logRepository.log(
                LogLevel.Error,
                "Sync failed",
                details = message,
                tag = "Sync",
                throwable = err
            )
            state.update { it.copy(sync = SyncState.Error(message)) }
            if (onError != null) {
                withContext(Dispatchers.Main) {
                    onError(formatSyncErrorMessage(message))
                }
            }
        }
    }

    private fun formatSyncErrorMessage(message: String): String {
        val normalized = message.trim().lowercase()
        return if (normalized.contains("sync already in progress")) {
            message
        } else {
            "Sync failed: $message"
        }
    }

    private suspend fun performBatchedSync() {
        val repo = chatSyncRepository ?: return
        try {
            state.update { it.copy(sync = SyncState.Migrating(0, 0)) }
            withContext(Dispatchers.IO) {
                repo.syncWithProgress(migrationConfig) { progress: MigrationProgress ->
                    state.update {
                        it.copy(sync = SyncState.Migrating(progress.processed, progress.total))
                    }
                }
            }
            reloadSessions?.invoke()
            state.update { it.copy(sync = SyncState.Idle) }
        } catch (err: Throwable) {
            val message = syncErrorMessage(err)
            logRepository.log(
                LogLevel.Error,
                "Migration sync failed",
                details = message,
                tag = "Sync",
                throwable = err
            )
            state.update { it.copy(sync = SyncState.Error(message)) }
        }
    }

    private fun syncErrorMessage(error: Throwable): String {
        var current: Throwable? = error
        while (current != null) {
            val message = current.message
            if (!message.isNullOrBlank()) {
                return message
            }
            current = current.cause
        }
        return "Unknown error"
    }
}
