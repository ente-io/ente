package io.ente.ensu.domain.store

import io.ente.ensu.domain.llm.LlmModelTarget
import io.ente.ensu.domain.llm.LlmProvider
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.ModelSettingsState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

internal class ModelSettingsActions(
    private val state: MutableStateFlow<AppState>,
    private val llmProvider: LlmProvider,
    private val logRepository: LogRepository
) {
    private var scope: CoroutineScope? = null
    private var modelDownloadJob: Job? = null

    fun setScope(scope: CoroutineScope) {
        this.scope = scope
    }

    fun updateModelSettings(settings: ModelSettingsState) {
        state.update { appState ->
            appState.copy(modelSettings = settings)
        }
        refreshModelDownloadInfo()
    }

    fun resetModelSettings() {
        state.update { appState ->
            appState.copy(modelSettings = ModelSettingsState())
        }
        refreshModelDownloadInfo()
    }

    fun refreshModelDownloadInfo() {
        val target = resolveTarget(state.value.modelSettings)
        val isDownloaded = llmProvider.isModelDownloaded(target)
        state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isModelDownloaded = isDownloaded,
                    modelDownloadSizeBytes = if (isDownloaded) null else appState.chat.modelDownloadSizeBytes,
                    hasRequestedModelDownload = appState.chat.hasRequestedModelDownload || isDownloaded
                )
            )
        }

        if (!isDownloaded) {
            val scope = scope ?: return
            scope.launch {
                val size = llmProvider.estimateModelDownloadSize(target)
                state.update { appState ->
                    appState.copy(chat = appState.chat.copy(modelDownloadSizeBytes = size))
                }
            }
        }
    }

    fun startModelDownload(userInitiated: Boolean = true) {
        val scope = scope ?: return
        val currentState = state.value
        if (modelDownloadJob?.isActive == true) return
        if (currentState.chat.isDownloading || currentState.chat.isGenerating) return
        if (!userInitiated && !currentState.chat.hasRequestedModelDownload) return

        val target = resolveTarget(currentState.modelSettings)
        val isDownloaded = llmProvider.isModelDownloaded(target)
        if (isDownloaded) {
            state.update { appState ->
                appState.copy(
                    chat = appState.chat.copy(
                        isModelDownloaded = true,
                        modelDownloadSizeBytes = null,
                        hasRequestedModelDownload = if (userInitiated) true else appState.chat.hasRequestedModelDownload
                    )
                )
            }
        }

        modelDownloadJob?.cancel()
        if (!isDownloaded) {
            logRepository.log(
                LogLevel.Info,
                "Model download started",
                details = "model=${target.id}",
                tag = "Model"
            )
            state.update { appState ->
                appState.copy(
                    chat = appState.chat.copy(
                        isDownloading = true,
                        downloadPercent = 0,
                        downloadStatus = "Starting download...",
                        hasRequestedModelDownload = if (userInitiated) true else appState.chat.hasRequestedModelDownload
                    )
                )
            }
        }

        modelDownloadJob = scope.launch {
            var loggedComplete = false
            try {
                llmProvider.ensureModelReady(target) { progress ->
                    val downloading = (progress.percent in 0..99) || progress.status.contains("Loading", ignoreCase = true)
                    val finished = progress.status.contains("Ready", ignoreCase = true)
                    if (!isDownloaded && finished && !loggedComplete) {
                        loggedComplete = true
                        logRepository.log(
                            LogLevel.Info,
                            "Model download complete",
                            details = "model=${target.id}",
                            tag = "Model"
                        )
                    }
                    state.update { appState ->
                        appState.copy(
                            chat = appState.chat.copy(
                                isDownloading = downloading && !finished,
                                downloadPercent = progress.percent.takeIf { it >= 0 },
                                downloadStatus = progress.status,
                                isModelDownloaded = if (finished) true else appState.chat.isModelDownloaded,
                                modelDownloadSizeBytes = if (finished) null else appState.chat.modelDownloadSizeBytes
                            )
                        )
                    }
                }
            } catch (err: Throwable) {
                val cancelled = err is kotlinx.coroutines.CancellationException ||
                    err.message?.contains("cancel", ignoreCase = true) == true
                state.update { appState ->
                    appState.copy(
                        chat = appState.chat.copy(
                            isDownloading = false,
                            downloadPercent = null,
                            downloadStatus = if (cancelled) "Download cancelled" else "Download failed",
                            hasRequestedModelDownload = if (cancelled) false else appState.chat.hasRequestedModelDownload
                        )
                    )
                }
                if (cancelled) {
                    if (!isDownloaded) {
                        logRepository.log(LogLevel.Info, "Model download cancelled", tag = "Model")
                    }
                } else {
                    logRepository.log(
                        LogLevel.Error,
                        if (isDownloaded) "Model load failed" else "Model download failed",
                        details = err.message,
                        tag = "Model",
                        throwable = err
                    )
                }
            } finally {
                modelDownloadJob = null
                refreshModelDownloadInfo()
            }
        }
    }

    fun cancelModelDownload() {
        modelDownloadJob?.cancel()
        modelDownloadJob = null
        llmProvider.cancelDownload()
        state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isDownloading = false,
                    downloadPercent = null,
                    downloadStatus = "Download cancelled",
                    hasRequestedModelDownload = false
                )
            )
        }
        refreshModelDownloadInfo()
    }

    fun resolveTarget(settings: ModelSettingsState): LlmModelTarget {
        val useCustom = settings.useCustomModel && settings.modelUrl.isNotBlank()
        val url = if (useCustom) settings.modelUrl else DEFAULT_MODEL_URL
        val mmproj = if (useCustom) settings.mmprojUrl.takeIf { it.isNotBlank() } else DEFAULT_MMPROJ_URL
        val contextLength = settings.contextLength.toIntOrNull()
        val maxTokens = settings.maxTokens.toIntOrNull()
        val id = if (useCustom) "custom:${url.hashCode()}" else "default"

        return LlmModelTarget(
            id = id,
            url = url,
            mmprojUrl = mmproj,
            contextLength = contextLength,
            maxTokens = maxTokens
        )
    }

    fun resolveTemperature(settings: ModelSettingsState): Float {
        val temperature = settings.temperature.trim().toFloatOrNull()
        val resolved = temperature?.takeIf { it >= 0f } ?: DEFAULT_TEMPERATURE
        return resolved.coerceIn(0.35f, 0.7f)
    }

    companion object {
        private const val DEFAULT_MODEL_URL =
            "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf"
        private const val DEFAULT_MMPROJ_URL =
            "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
        private const val DEFAULT_TEMPERATURE = 0.5f
    }
}
