package io.ente.ensu.domain.store

import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.AuthState
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.state.AppState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

internal class AuthStoreActions(
    private val state: MutableStateFlow<AppState>,
    private val logRepository: LogRepository,
    private val onSync: () -> Unit
) {
    fun signIn(email: String) {
        state.update { appState ->
            appState.copy(auth = AuthState(isLoggedIn = true, email = email))
        }
        // Do not log PII like user email.
        logRepository.log(LogLevel.Info, "Signed in", tag = "Auth")
        onSync()
    }

    fun signOut() {
        state.update { appState ->
            appState.copy(auth = AuthState())
        }
        logRepository.log(LogLevel.Info, "Signed out", tag = "Auth")
    }
}
