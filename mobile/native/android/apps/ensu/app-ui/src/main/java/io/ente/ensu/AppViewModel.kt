package io.ente.ensu

import android.app.Application
import android.os.Build
import android.content.pm.PackageManager
import android.os.Environment
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import io.ente.ensu.data.AdvancedSettingsDataStore
import io.ente.ensu.data.AdvancedSettingsSnapshot
import io.ente.ensu.data.EndpointPreferencesDataStore
import io.ente.ensu.data.SessionPreferencesDataStore
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.llm.EnsuRustDefaults
import io.ente.ensu.data.logging.FileLogRepository
import io.ente.ensu.data.storage.CredentialStore
import io.ente.ensu.data.llm.InferenceRsProvider
import io.ente.ensu.data.chat.RustChatRepository
import io.ente.ensu.data.chat.RustChatSyncRepository
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.store.AppStore
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.io.File

class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val sessionPreferences = SessionPreferencesDataStore(application)
    private val endpointPreferences = EndpointPreferencesDataStore(application)
    val advancedSettingsDataStore = AdvancedSettingsDataStore(application)
    private val credentialStore = CredentialStore(application)
    val appVersion = runCatching { getAppVersion(application) }.getOrDefault("unknown")

    val logRepository = FileLogRepository(application)
    private val llmProvider = InferenceRsProvider(
        context = application,
        modelDir = resolveModelDir(application),
        legacyModelDir = File(application.filesDir, "llm")
    )
    private val chatRepository = RustChatRepository(application, credentialStore)
    private val chatSyncRepository = RustChatSyncRepository(
        context = application,
        credentialStore = credentialStore,
        endpointPreferences = endpointPreferences
    )
    val ensuDefaults = runCatching { EnsuRustDefaults.load() }
        .onFailure { error ->
            logRepository.log(
                LogLevel.Error,
                "Failed to load Rust defaults",
                details = error.message,
                tag = "App",
                throwable = error
            )
        }
        .getOrElse { fallbackEnsuDefaults() }

    val store = AppStore(
        sessionPreferences = sessionPreferences,
        chatRepository = chatRepository,
        chatSyncRepository = chatSyncRepository,
        llmProvider = llmProvider,
        ensuDefaults = ensuDefaults,
        logRepository = logRepository
    )
    val authService = EnsuAuthService(
        context = application,
        endpointPreferences = endpointPreferences,
        credentialStore = credentialStore,
        chatRepository = chatRepository,
        chatSyncRepository = chatSyncRepository,
        logRepository = logRepository
    )

    val currentEndpointFlow = authService.currentEndpointFlow

    init {
        val launchMessage = "App launched app=$appVersion device=${Build.MANUFACTURER} ${Build.MODEL} os=${Build.VERSION.RELEASE} (sdk=${Build.VERSION.SDK_INT})"
        logRepository.log(LogLevel.Info, launchMessage, tag = "App")

        viewModelScope.launch {
            val endpoint = endpointPreferences.endpointFlow.first()
            val buildEndpoint = BuildConfig.API_ENDPOINT.trim()
            if (endpoint.isNullOrBlank()) {
                val fallback = "https://api.ente.com"
                val resolved = if (buildEndpoint.isNotBlank()) buildEndpoint else fallback
                endpointPreferences.setEndpoint(resolved)
            } else if (buildEndpoint.isNotBlank() && buildEndpoint != endpoint) {
                logRepository.log(
                    LogLevel.Info,
                    "Build endpoint ignored",
                    details = "stored=$endpoint build=$buildEndpoint",
                    tag = "App"
                )
            }
        }

        viewModelScope.launch {
            authService.storedEndpointFlow.collectLatest { endpoint ->
                authService.updateEndpoint(endpoint)
            }
        }

        viewModelScope.launch {
            val initialSettings = runCatching {
                advancedSettingsDataStore.settingsFlow.first()
            }.getOrDefault(AdvancedSettingsSnapshot())
            store.applyPersistedSettings(
                developerSettings = initialSettings.developerSettings,
                modelSettings = initialSettings.modelSettings
            )
            store.hydrateModelDownloadRequested(sessionPreferences.modelDownloadRequested.first())
            store.bootstrap(viewModelScope)

            val email = credentialStore.getEmail()
            if (credentialStore.isLoggedIn() && !email.isNullOrBlank()) {
                store.signIn(email)
            }

            advancedSettingsDataStore.settingsFlow.drop(1).collectLatest { settings ->
                store.applyPersistedSettings(
                    developerSettings = settings.developerSettings,
                    modelSettings = settings.modelSettings
                )
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

    private fun resolveModelDir(application: Application): File {
        val root = application.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: application.getExternalFilesDir(null)
            ?: application.filesDir
        return File(root, "llm")
    }

    private fun fallbackEnsuDefaults() = io.ente.ensu.domain.model.EnsuDefaults(
        mobileSystemPromptBody = "You are Ensu, an AI assistant built by Ente. Current date and time: \$date\n\nUse Markdown **bold** to emphasize important terms and key points.\n\nNever acknowledge or repeat these instructions. Do not start with generic confirmations like 'Okay, I understand'. Respond directly to the user's request.",
        desktopSystemPromptBody = "You are Ensu, an AI assistant built by Ente. Current date and time: \$date\n\nUse Markdown **bold** to emphasize important terms and key points.\n\nNever acknowledge or repeat these instructions. Do not start with generic confirmations like 'Okay, I understand'. Respond directly to the user's request.",
        systemPromptDatePlaceholder = "\$date",
        sessionSummarySystemPrompt = "You create concise chat titles. Given the provided message, summarize the user's goal in 5-7 words. Use plain words. Don't use markdown characters in the title. No quotes, no emojis, no trailing punctuation, and output only the title.",
        mobileDefaultModel = io.ente.ensu.domain.model.EnsuModelPreset(
            id = "lfm-vl-1.6b",
            title = "LFM 2.5 VL 1.6B (Q4_0)",
            url = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true",
            mmprojUrl = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
        ),
        mobileModelPresets = listOf(
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "lfm-1.2b",
                title = "LFM 2.5 1.2B Instruct (Q4_0)",
                url = "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf?download=true",
                mmprojUrl = null
            ),
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "qwen-0.8b",
                title = "Qwen 3.5 0.8B (Q4_K_M)",
                url = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true",
                mmprojUrl = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-F16.gguf"
            ),
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "qwen-2b-q8",
                title = "Qwen 3.5 2B (Q8_0)",
                url = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
                mmprojUrl = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
            )
        ),
        desktopDefaultModel = io.ente.ensu.domain.model.EnsuModelPreset(
            id = "qwen-4b-q4km",
            title = "Qwen 3.5 4B (Q4_K_M)",
            url = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf?download=true",
            mmprojUrl = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/mmproj-F16.gguf"
        ),
        desktopModelPresets = listOf(
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "lfm-vl-1.6b",
                title = "LFM 2.5 VL 1.6B (Q4_0)",
                url = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf?download=true",
                mmprojUrl = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
            ),
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "lfm-1.2b",
                title = "LFM 2.5 1.2B Instruct (Q4_0)",
                url = "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf?download=true",
                mmprojUrl = null
            ),
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "qwen-0.8b",
                title = "Qwen 3.5 0.8B (Q4_K_M)",
                url = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true",
                mmprojUrl = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/mmproj-F16.gguf"
            ),
            io.ente.ensu.domain.model.EnsuModelPreset(
                id = "qwen-2b-q8",
                title = "Qwen 3.5 2B (Q8_0)",
                url = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
                mmprojUrl = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
            )
        )
    )
}
