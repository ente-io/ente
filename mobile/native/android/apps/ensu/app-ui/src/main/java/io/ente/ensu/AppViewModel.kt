package io.ente.ensu

import android.app.Application
import android.os.Build
import android.content.pm.PackageManager
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.SessionPreferencesDataStore
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.logging.FileLogRepository
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.data.llm.InferenceRsProvider
import io.ente.ensu.data.chat.RustChatRepository
import io.ente.ensu.data.chat.RustChatSyncRepository
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.store.AppStore
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.io.File

class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val sessionPreferences = SessionPreferencesDataStore(application)
    private val endpointPreferences = EndpointPreferencesDataStore(application)
    private val credentialStore = CredentialStore(application)

    private companion object {
        const val fixedEndpoint = "https://1227635d8108.ngrok-free.app"
    }

    val logRepository = FileLogRepository(application)
    private val llmProvider = InferenceRsProvider(
        modelDir = File(application.filesDir, "llm")
    )
    private val chatRepository = RustChatRepository(application, credentialStore)
    private val chatSyncRepository = RustChatSyncRepository(
        context = application,
        credentialStore = credentialStore,
        endpointPreferences = endpointPreferences
    )

    val store = AppStore(
        sessionPreferences = sessionPreferences,
        chatRepository = chatRepository,
        chatSyncRepository = chatSyncRepository,
        llmProvider = llmProvider,
        logRepository = logRepository
    )
    val authService = EnsuAuthService(
        context = application,
        endpointPreferences = endpointPreferences,
        credentialStore = credentialStore,
        logRepository = logRepository
    )

    val currentEndpointFlow = authService.currentEndpointFlow

    init {
        val appVersion = runCatching { getAppVersion(application) }.getOrDefault("unknown")
        val deviceInfo = "app=$appVersion\ndevice=${Build.MANUFACTURER} ${Build.MODEL}\nos=${Build.VERSION.RELEASE} (sdk=${Build.VERSION.SDK_INT})"
        logRepository.log(LogLevel.Info, "App launched", details = deviceInfo, tag = "App")

        runBlocking {
            val endpoint = endpointPreferences.endpointFlow.first()
            if (endpoint.isNullOrBlank()) {
                endpointPreferences.setEndpoint(fixedEndpoint)
            }
        }

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

    @Suppress("DEPRECATION")
    private fun getAppVersion(application: Application): String {
        val packageManager = application.packageManager
        val packageName = application.packageName
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
        } else {
            packageManager.getPackageInfo(packageName, 0)
        }
        val versionName = packageInfo.versionName ?: "unknown"
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            packageInfo.versionCode.toLong()
        }
        return "$versionName+$versionCode"
    }
}
