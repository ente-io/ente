package io.ente.ensu.domain.store

import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.state.AppState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
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
            try {
                logRepository.log(LogLevel.Info, "Sync started", tag = "Sync")
                withContext(Dispatchers.IO) {
                    chatSyncRepository?.sync()
                }
                reloadSessions?.invoke()
                logRepository.log(LogLevel.Info, "Sync success", tag = "Sync")
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
                if (onError != null) {
                    withContext(Dispatchers.Main) {
                        onError("Sync failed: $message")
                    }
                }
            }
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
