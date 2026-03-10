package io.ente.ensu.domain.store

import io.ente.ensu.domain.llm.LlmModelTarget
import io.ente.ensu.domain.llm.LlmProvider
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.ModelSettingsState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
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
                    appState.copy(
                        chat = appState.chat.copy(
                            modelDownloadSizeBytes = size ?: appState.chat.modelDownloadSizeBytes
                        )
                    )
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
            val progressTracker = DownloadProgressTracker(
                initialPercent = if (isDownloaded) null else 0,
                initialStatus = if (isDownloaded) null else "Starting download..."
            )
            try {
                var retryCount = 0
                while (true) {
                    try {
                        llmProvider.ensureModelReady(target) { progress ->
                            val resolvedProgress = progressTracker.resolve(progress)
                            if (!isDownloaded && resolvedProgress.isFinished && !loggedComplete) {
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
                                        isDownloading = resolvedProgress.isDownloading,
                                        downloadPercent = resolvedProgress.percent,
                                        downloadStatus = resolvedProgress.status,
                                        isModelDownloaded = if (resolvedProgress.isFinished) true else appState.chat.isModelDownloaded,
                                        modelDownloadSizeBytes = if (resolvedProgress.isFinished) null else appState.chat.modelDownloadSizeBytes
                                    )
                                )
                            }
                        }
                        break
                    } catch (err: Throwable) {
                        if (!shouldRetryDownload(err, retryCount)) {
                            throw err
                        }

                        retryCount += 1
                        delay(retryDelayMs(retryCount))
                    }
                }
            } catch (err: Throwable) {
                val cancelled = err is kotlinx.coroutines.CancellationException ||
                    err.message?.contains("cancel", ignoreCase = true) == true
                val failureMessage = if (cancelled) {
                    "Download cancelled"
                } else {
                    userFacingDownloadError(err, isDownloaded)
                }
                state.update { appState ->
                    appState.copy(
                        chat = appState.chat.copy(
                            isDownloading = false,
                            downloadPercent = null,
                            downloadStatus = failureMessage,
                            hasRequestedModelDownload = false
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
        val maxTokens = settings.maxTokens.toIntOrNull()?.takeIf { it > 0 }
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
        private const val MAX_DOWNLOAD_RETRIES = 5
        private const val RETRY_DELAY_BASE_MS = 1500L
        private const val RETRY_DELAY_MAX_MS = 12000L
        private const val DEFAULT_MODEL_URL =
            "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true"
        private const val DEFAULT_MMPROJ_URL =
            "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
        private const val DEFAULT_TEMPERATURE = 0.5f
    }

    private fun shouldRetryDownload(err: Throwable, retryCount: Int): Boolean {
        if (retryCount >= MAX_DOWNLOAD_RETRIES) return false
        if (err is kotlinx.coroutines.CancellationException) return false
        if (isOutOfStorageError(err)) return false
        val message = err.message.orEmpty()
        if (message.contains("not GGUF", ignoreCase = true)) return false
        if (message.contains("HTTP 401", ignoreCase = true) ||
            message.contains("HTTP 403", ignoreCase = true) ||
            message.contains("HTTP 404", ignoreCase = true)
        ) {
            return false
        }
        return true
    }

    private fun retryDelayMs(retryCount: Int): Long {
        val multiplier = 1L shl (retryCount - 1).coerceAtLeast(0)
        return (RETRY_DELAY_BASE_MS * multiplier).coerceAtMost(RETRY_DELAY_MAX_MS)
    }

    private fun userFacingDownloadError(err: Throwable, wasAlreadyDownloaded: Boolean): String {
        if (isOutOfStorageError(err)) {
            return "Not enough storage space to download the model. Please free up space and try again."
        }
        return if (wasAlreadyDownloaded) "Model load failed" else "Download failed. Please try again."
    }

    private fun isOutOfStorageError(err: Throwable): Boolean {
        var current: Throwable? = err
        while (current != null) {
            val message = current.message.orEmpty()
            if (message.contains("ENOSPC", ignoreCase = true) ||
                message.contains("No space left on device", ignoreCase = true) ||
                message.contains("disk is full", ignoreCase = true) ||
                message.contains("not enough storage", ignoreCase = true)
            ) {
                return true
            }
            current = current.cause
        }
        return false
    }
}
