package io.ente.ensu

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.SessionPreferencesDataStore
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.logging.InMemoryLogRepository
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.data.llm.InferenceRsProvider
import io.ente.ensu.domain.store.AppStore
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.io.File

class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val sessionPreferences = SessionPreferencesDataStore(application)
    private val endpointPreferences = EndpointPreferencesDataStore(application)
    private val credentialStore = CredentialStore(application)

    val logRepository = InMemoryLogRepository()
    private val llmProvider = InferenceRsProvider(
        modelDir = File(application.filesDir, "llm")
    )
    val store = AppStore(sessionPreferences, llmProvider = llmProvider, logRepository = logRepository)
    val authService = EnsuAuthService(
        context = application,
        endpointPreferences = endpointPreferences,
        credentialStore = credentialStore,
        logRepository = logRepository
    )

    val currentEndpointFlow = authService.currentEndpointFlow

    init {
        store.bootstrap(viewModelScope)
        val email = credentialStore.getEmail()
        if (credentialStore.isLoggedIn() && !email.isNullOrBlank()) {
            store.signIn(email)
        }

        viewModelScope.launch {
            authService.storedEndpointFlow.collectLatest { endpoint ->
                authService.updateEndpoint(endpoint)
            }
        }
    }
}
