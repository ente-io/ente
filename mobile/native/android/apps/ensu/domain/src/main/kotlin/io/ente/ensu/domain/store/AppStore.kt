package io.ente.ensu.domain.store

import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.ensu.domain.llm.LlmMessage
import io.ente.ensu.domain.llm.LlmMessageRole
import io.ente.ensu.domain.llm.LlmModelTarget
import io.ente.ensu.domain.llm.LlmProvider
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentDownloadItem
import io.ente.ensu.domain.model.AttachmentDownloadStatus
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.AuthState
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.model.MessageAuthor
import io.ente.ensu.domain.model.sessionTitleFromText
import io.ente.ensu.domain.preferences.SessionPreferences
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.ModelSettingsState
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.logging.NoOpLogRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.math.abs
import kotlin.math.max

class AppStore(
    private val sessionPreferences: SessionPreferences,
    private val chatRepository: io.ente.ensu.domain.chat.ChatRepository,
    private val chatSyncRepository: ChatSyncRepository? = null,
    private val llmProvider: LlmProvider,
    private val clock: () -> Long = { System.currentTimeMillis() },
    private val logRepository: LogRepository = NoOpLogRepository
) {
    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    private val messageStore = mutableMapOf<String, MutableList<ChatMessage>>()
    private val branchSelections = mutableMapOf<String, MutableMap<String, String>>()
    private val sessionSummaries = mutableMapOf<String, String>()
    private var scope: CoroutineScope? = null
    private var generationJob: Job? = null
    private var modelDownloadJob: Job? = null
    private var sessionSummaryJob: Job? = null
    private var stopRequested = false
    private var streamingParentId: String? = null
    private var activeGenerationToken = 0L
    private var pendingSyncRequested = false
    private var pendingSyncErrorHandler: ((String) -> Unit)? = null
    private var pendingSyncSuccessHandler: (() -> Unit)? = null

    private val sessionSummarySystemPrompt =
        "You are a title generator. Rewrite the message in 4-5 words for a chat title. Reply with only the title, no quotes."
    private val sessionSummaryMaxWords = 5

    private val attachmentDownloads = mutableMapOf<String, AttachmentDownloadItem>()
    private val attachmentDownloadQueue = ArrayDeque<String>()
    private val attachmentDownloadActive = mutableMapOf<String, Job>()
    private val maxAttachmentDownloadConcurrency = 2

    fun bootstrap(scope: CoroutineScope) {
        this.scope = scope

        sessionSummaries.clear()
        sessionSummaries.putAll(runBlocking { sessionPreferences.sessionSummaries.first() }.mapKeys { it.key.lowercase() })

        if (_state.value.chat.sessions.isEmpty()) {
            loadSessionsFromDb()
        }

        refreshModelDownloadInfo()

        scope.launch {
            sessionPreferences.sessionSummaries.collectLatest { summaries ->
                sessionSummaries.clear()
                sessionSummaries.putAll(summaries.mapKeys { it.key.lowercase() })
                applySessionSummariesToState()
            }
        }

    }

    private fun refreshModelDownloadInfo() {
        val target = resolveTarget(_state.value.modelSettings)
        val isDownloaded = llmProvider.isModelDownloaded(target)
        _state.update { appState ->
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
                _state.update { appState ->
                    appState.copy(chat = appState.chat.copy(modelDownloadSizeBytes = size))
                }
            }
        }
    }

    fun createNewSession(): String {
        generationJob?.cancel()
        llmProvider.stopGeneration()
        invalidateGenerationToken()
        streamingParentId = null
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isGenerating = false,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = null,
                    downloadPercent = null,
                    downloadStatus = null
                )
            )
        }

        val session = chatRepository.createSession("New Chat")
        messageStore[session.id] = mutableListOf()
        branchSelections[session.id] = mutableMapOf()

        _state.update { appState ->
            val updatedSessions = listOf(session) + appState.chat.sessions
            appState.copy(
                chat = appState.chat.copy(
                    sessions = updatedSessions,
                    currentSessionId = session.id,
                    messageText = "",
                    attachments = emptyList(),
                    editingMessageId = null
                )
            )
        }
        // Session is empty, no DB load needed.
        rebuildChatState(session.id)
        updateAttachmentDownloadState()
        logRepository.log(LogLevel.Info, "Session created", tag = "Chat")
        return session.id
    }

    fun startNewSessionDraft() {
        generationJob?.cancel()
        llmProvider.stopGeneration()
        invalidateGenerationToken()
        streamingParentId = null
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    currentSessionId = null,
                    messages = emptyList(),
                    branchSelections = emptyMap(),
                    isGenerating = false,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = null,
                    downloadPercent = null,
                    downloadStatus = null,
                    messageText = "",
                    attachments = emptyList(),
                    editingMessageId = null
                )
            )
        }
        updateAttachmentDownloadState()
    }

    fun selectSession(sessionId: String) {
        generationJob?.cancel()
        llmProvider.stopGeneration()
        invalidateGenerationToken()
        streamingParentId = null
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    currentSessionId = sessionId,
                    isGenerating = false,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = null,
                    downloadPercent = null,
                    downloadStatus = null
                )
            )
        }
        loadMessagesFromDb(sessionId)
        rebuildChatState(sessionId)
        ensureAttachmentsAvailable(sessionId)
    }

    fun deleteSession(sessionId: String) {
        val currentState = _state.value
        val isCurrent = currentState.chat.currentSessionId == sessionId

        if (isCurrent) {
            generationJob?.cancel()
            llmProvider.stopGeneration()
            invalidateGenerationToken()
            streamingParentId = null
        }

        chatRepository.deleteSession(sessionId)
        messageStore.remove(sessionId)
        branchSelections.remove(sessionId)
        purgeAttachmentDownloads(sessionId)
        sessionSummaries.remove(sessionId.lowercase())
        scope?.launch { sessionPreferences.setSessionSummary(sessionId, null) }

        val remaining = currentState.chat.sessions.filterNot { it.id == sessionId }
        val sessions = remaining

        sessions.forEach { session ->
            messageStore.getOrPut(session.id) { mutableListOf() }
            branchSelections.getOrPut(session.id) { mutableMapOf() }
        }

        val newCurrent = if (isCurrent) {
            sessions.firstOrNull()?.id
        } else {
            currentState.chat.currentSessionId?.takeIf { id -> sessions.any { it.id == id } }
                ?: sessions.firstOrNull()?.id
        }

        _state.update { appState ->
            val resetCurrent = isCurrent
            appState.copy(
                chat = appState.chat.copy(
                    sessions = sessions,
                    currentSessionId = newCurrent,
                    isGenerating = if (resetCurrent) false else appState.chat.isGenerating,
                    isDownloading = if (resetCurrent) false else appState.chat.isDownloading,
                    streamingResponse = if (resetCurrent) "" else appState.chat.streamingResponse,
                    streamingParentId = if (resetCurrent) null else appState.chat.streamingParentId,
                    downloadPercent = if (resetCurrent) null else appState.chat.downloadPercent,
                    downloadStatus = if (resetCurrent) null else appState.chat.downloadStatus,
                    messageText = if (resetCurrent) "" else appState.chat.messageText,
                    attachments = if (resetCurrent) emptyList() else appState.chat.attachments,
                    editingMessageId = if (resetCurrent) null else appState.chat.editingMessageId
                )
            )
        }

        if (newCurrent != null) {
            loadMessagesFromDb(newCurrent)
            rebuildChatState(newCurrent)
            ensureAttachmentsAvailable(newCurrent)
        } else {
            _state.update { appState ->
                appState.copy(chat = appState.chat.copy(messages = emptyList(), branchSelections = emptyMap()))
            }
        }

        scope?.launch { sessionPreferences.setSelectedSessionId(newCurrent) }
        syncNow()
        logRepository.log(LogLevel.Info, "Session deleted", tag = "Chat")
    }

    fun persistSelectedSession(scope: CoroutineScope, sessionId: String?) {
        scope.launch {
            sessionPreferences.setSelectedSessionId(sessionId)
        }
    }

    fun updateMessageText(value: String) {
        _state.update { appState ->
            appState.copy(chat = appState.chat.copy(messageText = value))
        }
    }

    fun updateBranchSelection(messageId: String, selectedIndex: Int) {
        val sessionId = _state.value.chat.currentSessionId ?: return
        val messages = messageStore[sessionId].orEmpty()
        val byId = messages.associateBy { it.id }
        val message = byId[messageId] ?: return
        val parentKey = message.parentId?.takeIf { byId.containsKey(it) } ?: "__root__"
        val siblings = dedupeSiblings(buildChildrenMap(messages)[parentKey].orEmpty())
        if (siblings.isEmpty()) return
        val index = (selectedIndex - 1).coerceIn(0, siblings.lastIndex)
        val selectionMap = branchSelections.getOrPut(sessionId) { mutableMapOf() }
        selectionMap[parentKey] = siblings[index].id
        rebuildChatState(sessionId)
    }

    fun beginEditing(messageId: String) {
        val sessionId = _state.value.chat.currentSessionId ?: return
        val message = messageStore[sessionId]?.firstOrNull { it.id == messageId } ?: return
        if (message.author != MessageAuthor.User) return

        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    editingMessageId = message.id,
                    messageText = message.text,
                    attachments = message.attachments
                )
            )
        }
    }

    fun cancelEditing() {
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    editingMessageId = null,
                    messageText = "",
                    attachments = emptyList()
                )
            )
        }
    }

    fun setAttachmentProcessing(isProcessing: Boolean) {
        _state.update { appState ->
            appState.copy(chat = appState.chat.copy(isProcessingAttachments = isProcessing))
        }
    }

    fun addAttachment(attachment: Attachment) {
        if (_state.value.chat.isGenerating || _state.value.chat.isDownloading || _state.value.chat.isAttachmentDownloadBlocked) return

        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    attachments = appState.chat.attachments + attachment,
                    isProcessingAttachments = false
                )
            )
        }
    }

    fun removeAttachment(attachment: Attachment) {
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    attachments = appState.chat.attachments.filterNot { it.id == attachment.id }
                )
            )
        }
    }

    fun stopGeneration() {
        stopRequested = true
        llmProvider.stopGeneration()
    }

    fun startModelDownload(userInitiated: Boolean = true) {
        val scope = scope ?: return
        val currentState = _state.value
        if (modelDownloadJob?.isActive == true) return
        if (currentState.chat.isDownloading || currentState.chat.isGenerating) return
        if (!userInitiated && !currentState.chat.hasRequestedModelDownload) return

        val target = resolveTarget(currentState.modelSettings)
        val isDownloaded = llmProvider.isModelDownloaded(target)
        if (isDownloaded) {
            _state.update { appState ->
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
            _state.update { appState ->
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
                    _state.update { appState ->
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
                _state.update { appState ->
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

    fun cancelDownload() {
        generationJob?.cancel()
        modelDownloadJob?.cancel()
        modelDownloadJob = null
        llmProvider.cancelDownload()
        invalidateGenerationToken()
        streamingParentId = null
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isGenerating = false,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = null,
                    downloadPercent = null,
                    downloadStatus = "Download cancelled",
                    hasRequestedModelDownload = false
                )
            )
        }
        refreshModelDownloadInfo()
    }

    fun retryAssistantMessage(messageId: String) {
        val sessionId = _state.value.chat.currentSessionId ?: return
        val message = messageStore[sessionId]?.firstOrNull { it.id == messageId } ?: return
        if (message.author != MessageAuthor.Assistant) return
        val parentId = message.parentId ?: return
        val parent = messageStore[sessionId]?.firstOrNull { it.id == parentId } ?: return

        if (missingAttachments(sessionId).isNotEmpty()) {
            ensureAttachmentsAvailable(sessionId)
            return
        }
        llmProvider.resetContext()
        startGeneration(sessionId, parent)
        requestSync()
    }

    fun sendMessage() {
        val currentState = _state.value
        if (currentState.chat.isGenerating || currentState.chat.isDownloading) return
        val text = currentState.chat.messageText.trim()
        val attachments = currentState.chat.attachments
        if (text.isEmpty() && attachments.isEmpty()) return

        val sessionId = currentState.chat.currentSessionId ?: createNewSession()
        if (missingAttachments(sessionId).isNotEmpty()) {
            ensureAttachmentsAvailable(sessionId)
            return
        }
        val timestamp = clock()

        val editingMessageId = currentState.chat.editingMessageId
        val parentId = if (editingMessageId != null) {
            val existing = messageStore[sessionId]?.firstOrNull { it.id == editingMessageId }
            existing?.parentId
        } else {
            buildSelectedPath(sessionId).lastOrNull()?.id
        }

        val userMessage = chatRepository.insertMessage(
            sessionId = sessionId,
            parentId = parentId,
            author = MessageAuthor.User,
            text = text,
            attachments = attachments
        )

        messageStore.getOrPut(sessionId) { mutableListOf() }.add(userMessage)
        updateSelectionForParent(sessionId, parentId, userMessage.id)

        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    messageText = "",
                    attachments = emptyList(),
                    editingMessageId = null
                )
            )
        }

        updateCurrentSessionPreview(sessionId, text, timestamp)
        rebuildChatState(sessionId)
        startGeneration(sessionId, userMessage)
        requestSync()
        logRepository.log(
            LogLevel.Info,
            "Message sent",
            details = "len=${text.length} attachments=${attachments.size} edited=${editingMessageId != null}",
            tag = "Chat"
        )
    }

    fun updateModelSettings(state: ModelSettingsState) {
        _state.update { appState ->
            appState.copy(modelSettings = state)
        }
        refreshModelDownloadInfo()
    }

    fun resetModelSettings() {
        _state.update { appState ->
            appState.copy(modelSettings = ModelSettingsState())
        }
        refreshModelDownloadInfo()
    }

    fun signIn(email: String) {
        _state.update { appState ->
            appState.copy(auth = AuthState(isLoggedIn = true, email = email))
        }
        // Do not log PII like user email.
        logRepository.log(LogLevel.Info, "Signed in", tag = "Auth")
        syncNow()
    }

    fun signOut() {
        _state.update { appState ->
            appState.copy(auth = AuthState())
        }
        logRepository.log(LogLevel.Info, "Signed out", tag = "Auth")
    }

    fun syncNow(
        onSuccess: (() -> Unit)? = null,
        onError: ((String) -> Unit)? = null
    ) {
        requestSync(onSuccess, onError)
    }

    private fun requestSync(
        onSuccess: (() -> Unit)? = null,
        onError: ((String) -> Unit)? = null
    ) {
        if (_state.value.chat.isGenerating) {
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

    private fun syncAfterGeneration() {
        val handler = pendingSyncErrorHandler
        val successHandler = pendingSyncSuccessHandler
        val shouldAutoSync = _state.value.auth.isLoggedIn
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
                loadSessionsFromDb()
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

    fun cancelAttachmentDownload(attachmentId: String) {
        attachmentDownloadActive[attachmentId]?.cancel()
        attachmentDownloadActive.remove(attachmentId)
        attachmentDownloadQueue.removeAll { it == attachmentId }
        attachmentDownloads[attachmentId]?.let { item ->
            attachmentDownloads[attachmentId] = item.copy(status = AttachmentDownloadStatus.Canceled)
        }
        updateAttachmentDownloadState()
        startNextAttachmentDownloads()
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

    private fun purgeAttachmentDownloads(sessionId: String) {
        val ids = attachmentDownloads.values.filter { it.sessionId == sessionId }.map { it.id }
        ids.forEach { id ->
            attachmentDownloadActive[id]?.cancel()
            attachmentDownloadActive.remove(id)
            attachmentDownloadQueue.removeAll { it == id }
            attachmentDownloads.remove(id)
        }
        updateAttachmentDownloadState()
    }

    private fun ensureAttachmentsAvailable(sessionId: String) {
        val missing = missingAttachments(sessionId)
        if (missing.isEmpty()) {
            updateAttachmentDownloadState()
            return
        }
        queueAttachmentDownloads(missing)
        updateAttachmentDownloadState()
    }

    private fun missingAttachments(sessionId: String): List<AttachmentDownloadItem> {
        val messages = messageStore[sessionId].orEmpty()
        if (messages.isEmpty()) return emptyList()
        val seen = mutableSetOf<String>()
        val missing = mutableListOf<AttachmentDownloadItem>()

        for (message in messages) {
            for (attachment in message.attachments) {
                if (!seen.add(attachment.id)) continue
                val path = attachment.localPath
                if (path != null && File(path).exists()) {
                    attachmentDownloadActive[attachment.id]?.cancel()
                    attachmentDownloadActive.remove(attachment.id)
                    attachmentDownloadQueue.removeAll { it == attachment.id }
                    attachmentDownloads.remove(attachment.id)
                    continue
                }
                val existing = attachmentDownloads[attachment.id]
                val status = existing?.status ?: AttachmentDownloadStatus.Queued
                missing.add(
                    AttachmentDownloadItem(
                        id = attachment.id,
                        sessionId = sessionId,
                        name = attachment.name,
                        sizeBytes = attachment.sizeBytes,
                        status = status
                    )
                )
            }
        }

        return missing
    }

    private fun queueAttachmentDownloads(items: List<AttachmentDownloadItem>) {
        items.forEach { item ->
            val existing = attachmentDownloads[item.id]
            val updated = if (existing == null ||
                existing.status == AttachmentDownloadStatus.Failed ||
                existing.status == AttachmentDownloadStatus.Canceled
            ) {
                item
            } else {
                existing
            }
            attachmentDownloads[item.id] = updated
            if (updated.status != AttachmentDownloadStatus.Completed &&
                updated.status != AttachmentDownloadStatus.Canceled &&
                attachmentDownloadActive[item.id] == null &&
                !attachmentDownloadQueue.contains(item.id)
            ) {
                attachmentDownloadQueue.addLast(item.id)
            }
        }
        startNextAttachmentDownloads()
    }

    private fun startNextAttachmentDownloads() {
        val scope = scope ?: return
        while (attachmentDownloadActive.size < maxAttachmentDownloadConcurrency && attachmentDownloadQueue.isNotEmpty()) {
            val id = attachmentDownloadQueue.removeFirst()
            val item = attachmentDownloads[id] ?: continue
            if (item.status == AttachmentDownloadStatus.Completed || item.status == AttachmentDownloadStatus.Canceled) {
                continue
            }
            attachmentDownloads[id] = item.copy(status = AttachmentDownloadStatus.Downloading)
            updateAttachmentDownloadState()

            val job = scope.launch(Dispatchers.IO) {
                val result = runCatching {
                    chatSyncRepository?.downloadAttachment(id, item.sessionId)
                        ?: throw IllegalStateException("Sync unavailable")
                }
                val status = if (result.isSuccess) {
                    AttachmentDownloadStatus.Completed
                } else {
                    AttachmentDownloadStatus.Failed
                }
                withContext(Dispatchers.Main) {
                    attachmentDownloads[id]?.let { current ->
                        if (current.status != AttachmentDownloadStatus.Canceled) {
                            attachmentDownloads[id] = current.copy(status = status)
                        }
                    }
                    attachmentDownloadActive.remove(id)
                    updateAttachmentDownloadState()
                    startNextAttachmentDownloads()
                }
            }
            attachmentDownloadActive[id] = job
        }
    }

    private fun updateAttachmentDownloadState() {
        val currentSessionId = _state.value.chat.currentSessionId
        val missing = currentSessionId?.let { missingAttachments(it) }.orEmpty()
        val items = attachmentDownloads.values.sortedBy { it.name }
        val active = items.filter { it.status != AttachmentDownloadStatus.Canceled }
        val total = active.size
        val completed = active.count { it.status == AttachmentDownloadStatus.Completed }
        val hasPending = active.any {
            it.status == AttachmentDownloadStatus.Queued ||
                it.status == AttachmentDownloadStatus.Downloading ||
                it.status == AttachmentDownloadStatus.Failed
        }
        val progress = if (total > 0 && hasPending) (completed * 100 / total) else null
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    attachmentDownloads = items,
                    attachmentDownloadProgress = progress,
                    isAttachmentDownloadBlocked = missing.isNotEmpty()
                )
            )
        }
    }

    private fun nextGenerationToken(): Long {
        activeGenerationToken += 1
        return activeGenerationToken
    }

    private fun invalidateGenerationToken() {
        activeGenerationToken += 1
    }

    private fun isGenerationActive(token: Long, sessionId: String): Boolean {
        return token == activeGenerationToken && _state.value.chat.currentSessionId == sessionId
    }

    private fun startGeneration(sessionId: String, userMessage: ChatMessage) {
        val scope = scope ?: return
        generationJob?.cancel()
        sessionSummaryJob?.cancel()
        stopRequested = false
        val generationToken = nextGenerationToken()

        streamingParentId = userMessage.id
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isGenerating = true,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = userMessage.id,
                    downloadPercent = null,
                    downloadStatus = null,
                    hasRequestedModelDownload = true
                )
            )
        }
        rebuildChatState(sessionId)

        generationJob = scope.launch {
            val settings = _state.value.modelSettings
            val target = resolveTarget(settings)
            val isActive = { isGenerationActive(generationToken, sessionId) }
            try {
                llmProvider.ensureModelReady(target) { progress ->
                    if (!isActive()) return@ensureModelReady
                    val downloading = (progress.percent in 0..99) || progress.status.contains("Loading", ignoreCase = true)
                    val finished = progress.status.contains("Ready", ignoreCase = true)
                    _state.update { appState ->
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
                if (!isActive()) return@launch
                streamingParentId = null
                _state.update { appState ->
                    appState.copy(
                        chat = appState.chat.copy(
                            isGenerating = false,
                            isDownloading = false,
                            streamingParentId = null,
                            downloadPercent = null,
                            downloadStatus = if (cancelled) "Download cancelled" else null,
                            hasRequestedModelDownload = if (cancelled) false else appState.chat.hasRequestedModelDownload
                        )
                    )
                }
                if (!cancelled) {
                    logRepository.log(
                        LogLevel.Error,
                        "Model load failed",
                        details = err.message,
                        tag = "Model",
                        throwable = err
                    )
                }
                syncAfterGeneration()
                return@launch
            }

            if (!isActive()) return@launch

            val prompt = buildPrompt(userMessage.text, userMessage.attachments)
            val history = buildHistory(sessionId, prompt.text, userMessage.id)
            val systemMessage = LlmMessage(
                text = SYSTEM_PROMPT,
                role = LlmMessageRole.System
            )
            val llmMessages = listOf(systemMessage) + history + LlmMessage(
                text = prompt.text,
                role = LlmMessageRole.User,
                hasAttachments = userMessage.attachments.isNotEmpty()
            )

            val buffer = StringBuilder()
            var tokenCount = 0

            try {
                val summary = llmProvider.generateChat(
                    target = target,
                    messages = llmMessages,
                    imageFiles = prompt.imageFiles,
                    temperature = resolveTemperature(settings),
                    maxTokens = target.maxTokens ?: 1024
                ) { token ->
                    buffer.append(token)
                    tokenCount += estimateTokens(token)
                    if (isActive()) {
                        _state.update { appState ->
                            appState.copy(chat = appState.chat.copy(streamingResponse = buffer.toString()))
                        }
                    }
                }

                finishGeneration(
                    sessionId,
                    userMessage,
                    buffer,
                    tokenCount,
                    summary.totalTimeMs,
                    interrupted = false,
                    shouldUpdateUi = isActive()
                )
            } catch (err: Throwable) {
                val interrupted = stopRequested || err.message?.contains("cancel", ignoreCase = true) == true
                finishGeneration(
                    sessionId,
                    userMessage,
                    buffer,
                    tokenCount,
                    totalTimeMs = null,
                    interrupted = interrupted,
                    shouldUpdateUi = isActive()
                )
                if (!interrupted) {
                    logRepository.log(
                        LogLevel.Error,
                        "Generation failed",
                        details = err.message,
                        tag = "LLM",
                        throwable = err
                    )
                }
            }
        }
    }

    private fun finishGeneration(
        sessionId: String,
        parentMessage: ChatMessage,
        buffer: StringBuilder,
        tokenCount: Int,
        totalTimeMs: Long?,
        interrupted: Boolean,
        shouldUpdateUi: Boolean
    ) {
        val finalText = buffer.toString().trim()
        if (finalText.isNotEmpty()) {
            val tokensPerSecond = if (totalTimeMs != null && totalTimeMs > 0) {
                tokenCount.toDouble() / (totalTimeMs / 1000.0)
            } else null

            val inserted = chatRepository.insertMessage(
                sessionId = sessionId,
                parentId = parentMessage.id,
                author = MessageAuthor.Assistant,
                text = finalText,
                attachments = emptyList()
            )

            val assistantMessage = inserted.copy(
                isInterrupted = interrupted,
                tokensPerSecond = tokensPerSecond
            )

            messageStore.getOrPut(sessionId) { mutableListOf() }.add(assistantMessage)
            updateSelectionForParent(sessionId, parentMessage.id, assistantMessage.id)
            updateCurrentSessionPreview(sessionId, finalText, assistantMessage.timestampMillis)
        }

        if (shouldUpdateUi) {
            streamingParentId = null
            _state.update { appState ->
                appState.copy(
                    chat = appState.chat.copy(
                        isGenerating = false,
                        isDownloading = false,
                        streamingResponse = "",
                        streamingParentId = null,
                        downloadPercent = null,
                        downloadStatus = null
                    )
                )
            }
            rebuildChatState(sessionId)
            syncAfterGeneration()
        }
        scheduleSessionSummary(sessionId)
    }

    private fun updateCurrentSessionPreview(sessionId: String, preview: String, timestamp: Long) {
        _state.update { appState ->
            val updatedSessions = appState.chat.sessions.map { session ->
                if (session.id == sessionId) {
                    val shouldUpdateTitle = session.title.isBlank() || session.title.equals("New Chat", ignoreCase = true)
                    val updatedTitle = if (shouldUpdateTitle) {
                        sessionTitleFromText(preview, fallback = session.title)
                    } else {
                        session.title
                    }
                    if (updatedTitle != session.title) {
                        chatRepository.updateSessionTitle(sessionId, updatedTitle)
                    }
                    session.copy(
                        title = updatedTitle,
                        lastMessagePreview = preview,
                        updatedAtMillis = timestamp
                    )
                } else {
                    session
                }
            }
            appState.copy(chat = appState.chat.copy(sessions = updatedSessions))
        }
    }

    private fun applySessionSummariesToState() {
        _state.update { appState ->
            val updatedSessions = appState.chat.sessions.map { session ->
                val summary = sessionSummaries[session.id.lowercase()]
                if (!summary.isNullOrBlank() && summary != session.title) {
                    session.copy(title = summary)
                } else {
                    session
                }
            }
            appState.copy(chat = appState.chat.copy(sessions = updatedSessions))
        }
    }

    private fun scheduleSessionSummary(sessionId: String) {
        val scope = scope ?: return
        sessionSummaryJob?.cancel()
        if (sessionSummaries.containsKey(sessionId.lowercase())) return
        val summaryInput = buildSessionSummaryInput(sessionId) ?: return
        val target = resolveTarget(_state.value.modelSettings)

        sessionSummaryJob = scope.launch(Dispatchers.Default) {
            val summary = generateSessionSummary(
                input = summaryInput.text,
                fallback = summaryInput.fallback,
                target = target
            ) ?: return@launch
            if (!isActive) return@launch
            withContext(Dispatchers.Main) {
                applySessionSummary(sessionId, summary)
            }
        }
    }

    private data class SessionSummaryInput(val text: String, val fallback: String)

    private fun buildSessionSummaryInput(sessionId: String): SessionSummaryInput? {
        val messages = messageStore[sessionId].orEmpty()
        if (messages.isEmpty()) return null
        val firstUser = messages.filter { it.author == MessageAuthor.User }
            .minByOrNull { it.timestampMillis }
            ?: return null
        val assistants = messages.filter { it.author == MessageAuthor.Assistant }
        if (assistants.size != 1) return null
        val firstAssistant = assistants.first()
        if (firstAssistant.isInterrupted) return null

        val fallback = summarizeQuestion(firstUser.text)
        if (fallback.isBlank()) return null
        val input = "User: ${firstUser.text}\nAssistant: ${firstAssistant.text}"
        return SessionSummaryInput(text = input, fallback = fallback)
    }

    private suspend fun generateSessionSummary(
        input: String,
        fallback: String,
        target: LlmModelTarget
    ): String? {
        if (!llmProvider.isModelDownloaded(target)) {
            return sessionTitleFromText(fallback, fallback = fallback)
        }
        val cleanedInput = sanitizeTitleText(input)
        if (cleanedInput.isBlank()) return sessionTitleFromText(fallback, fallback = fallback)

        val messages = listOf(
            LlmMessage(text = sessionSummarySystemPrompt, role = LlmMessageRole.System),
            LlmMessage(text = cleanedInput, role = LlmMessageRole.User)
        )

        val buffer = StringBuilder()
        try {
            llmProvider.generateChat(
                target = target,
                messages = messages,
                imageFiles = emptyList(),
                temperature = 0.2f,
                maxTokens = 64
            ) { token ->
                buffer.append(token)
            }
        } catch (err: Throwable) {
            val fallbackSummary = summarizeQuestion(fallback)
            return if (fallbackSummary.isBlank()) null else sessionTitleFromText(fallbackSummary, fallback = fallback)
        }

        val raw = sanitizeTitleText(buffer.toString())
        if (raw.isBlank()) return null
        val words = raw.split(" ")
            .map { word -> word.trim { ch -> !ch.isLetterOrDigit() } }
            .filter { it.isNotBlank() }
        if (words.isEmpty()) return null
        val summary = words.take(sessionSummaryMaxWords).joinToString(" ")
        return sessionTitleFromText(summary, fallback = fallback)
    }

    private fun applySessionSummary(sessionId: String, summary: String) {
        val sanitized = sessionTitleFromText(summary, fallback = "New Chat")
        if (sanitized.isBlank()) return
        val summaryKey = sessionId.lowercase()
        if (sessionSummaries[summaryKey] == sanitized) return
        sessionSummaries[summaryKey] = sanitized
        scope?.launch { sessionPreferences.setSessionSummary(sessionId, sanitized) }
        chatRepository.updateSessionTitle(sessionId, sanitized)
        _state.update { appState ->
            val updatedSessions = appState.chat.sessions.map { session ->
                if (session.id == sessionId) {
                    session.copy(title = sanitized)
                } else {
                    session
                }
            }
            appState.copy(chat = appState.chat.copy(sessions = updatedSessions))
        }
    }

    private fun summarizeQuestion(text: String): String {
        val cleaned = sanitizeTitleText(text)
        if (cleaned.isBlank()) return ""
        val words = cleaned.split(" ")
            .map { word -> word.trim { ch -> !ch.isLetterOrDigit() } }
            .filter { it.isNotBlank() }
        if (words.isEmpty()) return ""
        val summaryWords = words.take(sessionSummaryMaxWords)
        return summaryWords.joinToString(" ")
    }

    private fun sanitizeTitleText(text: String): String {
        return text
            .replace(Regex("[\r\n\t]+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    private fun loadMessagesFromDb(sessionId: String) {
        val messages = chatRepository.getMessages(sessionId)
        messageStore[sessionId] = messages.toMutableList()
        // Reset branch selections for this session. (Branch selection is computed in-memory.)
        branchSelections.getOrPut(sessionId) { mutableMapOf() }.clear()
    }

    private fun rebuildChatState(sessionId: String?) {
        if (sessionId == null) {
            _state.update { appState ->
                appState.copy(chat = appState.chat.copy(messages = emptyList(), branchSelections = emptyMap()))
            }
            return
        }
        val messages = messageStore[sessionId].orEmpty()
        val path = buildSelectedPath(sessionId)
        val childrenMap = buildChildrenMap(messages)
        val selectionMap = branchSelections.getOrPut(sessionId) { mutableMapOf() }
        val branchSelectionIndices = mutableMapOf<String, Int>()
        val byId = messages.associateBy { it.id }

        val displayMessages = path.map { message ->
            val parentKey = message.parentId?.takeIf { byId.containsKey(it) } ?: "__root__"
            val siblings = dedupeSiblings(childrenMap[parentKey].orEmpty())
            if (siblings.size > 1) {
                val selectedId = selectionMap[parentKey]
                val index = siblings.indexOfFirst { it.id == selectedId }
                branchSelectionIndices[message.id] = if (index >= 0) index + 1 else siblings.size
            }
            message.copy(branchCount = max(1, siblings.size))
        }

        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    messages = displayMessages,
                    branchSelections = branchSelectionIndices
                )
            )
        }
    }

    private fun buildSelectedPath(sessionId: String): List<ChatMessage> {
        val messages = messageStore[sessionId].orEmpty()
        if (messages.isEmpty()) return emptyList()

        val byId = messages.associateBy { it.id }
        val childrenMap = buildChildrenMap(messages)
        val roots = dedupeSiblings(messages.filter { message ->
            val parentId = message.parentId
            parentId == null || byId[parentId] == null
        })
        if (roots.isEmpty()) return emptyList()

        val selectionMap = branchSelections.getOrPut(sessionId) { mutableMapOf() }
        var current = selectChild(selectionMap, "__root__", roots)
        val path = mutableListOf<ChatMessage>()
        val visited = mutableSetOf<String>()

        while (current != null && visited.add(current.id)) {
            path.add(current)
            if (current.id == streamingParentId) break
            val children = dedupeSiblings(childrenMap[current.id].orEmpty())
            if (children.isEmpty()) break
            current = selectChild(selectionMap, current.id, children)
        }
        return path
    }

    private fun selectChild(
        selectionMap: MutableMap<String, String>,
        selectionKey: String,
        candidates: List<ChatMessage>
    ): ChatMessage? {
        if (candidates.isEmpty()) return null
        val selectedId = selectionMap[selectionKey]
        val selected = candidates.firstOrNull { it.id == selectedId }
        return selected ?: candidates.last()
    }

    private fun buildChildrenMap(messages: List<ChatMessage>): Map<String, List<ChatMessage>> {
        val map = mutableMapOf<String, MutableList<ChatMessage>>()
        val byId = messages.associateBy { it.id }
        messages.forEach { message ->
            val parentKey = message.parentId?.takeIf { byId.containsKey(it) } ?: "__root__"
            map.getOrPut(parentKey) { mutableListOf() }.add(message)
        }
        return map
    }

    private fun dedupeSiblings(messages: List<ChatMessage>): List<ChatMessage> {
        if (messages.size <= 1) return messages.sortedBy { it.timestampMillis }
        val sorted = messages.sortedBy { it.timestampMillis }
        val result = mutableListOf<ChatMessage>()
        for (message in sorted) {
            val last = result.lastOrNull()
            if (last != null && isDuplicate(last, message)) {
                continue
            }
            result.add(message)
        }
        return result
    }

    private fun isDuplicate(left: ChatMessage, right: ChatMessage): Boolean {
        if (left.author != right.author) return false
        if (left.text != right.text) return false
        if (!attachmentsSignature(left.attachments).contentEquals(attachmentsSignature(right.attachments))) return false
        return abs(left.timestampMillis - right.timestampMillis) <= 2_000
    }

    private fun attachmentsSignature(attachments: List<Attachment>): Array<String> {
        return attachments.map { "${it.type}:${it.name}" }.toTypedArray()
    }

    private fun updateSelectionForParent(sessionId: String, parentId: String?, childId: String) {
        val selectionMap = branchSelections.getOrPut(sessionId) { mutableMapOf() }
        val selectionKey = parentId ?: "__root__"
        selectionMap[selectionKey] = childId
    }

    private fun buildPrompt(text: String, attachments: List<Attachment>): PromptResult {
        val builder = StringBuilder(text)
        val documents = attachments.filter { it.type == AttachmentType.Document }
        val images = attachments.filter { it.type == AttachmentType.Image }

        documents.forEachIndexed { index, attachment ->
            builder.append("\n\n----- BEGIN DOCUMENT: Document ${index + 1} -----\n")
            builder.append("Attached document: ${attachment.name}\n")
            builder.append("----- END DOCUMENT: Document ${index + 1} -----")
        }

        val imageFiles = images.mapNotNull { attachment ->
            val path = attachment.localPath ?: return@mapNotNull null
            java.io.File(path).takeIf { it.exists() }
        }

        if (imageFiles.isNotEmpty()) {
            builder.append("\n\n[")
            builder.append(imageFiles.size)
            builder.append(" image attachment")
            if (imageFiles.size > 1) builder.append("s")
            builder.append(" provided]")
            imageFiles.forEach {
                builder.append("\n")
                builder.append(MEDIA_MARKER)
            }
        }

        return PromptResult(builder.toString(), imageFiles)
    }

    private fun buildHistory(sessionId: String, promptText: String, currentMessageId: String): List<LlmMessage> {
        val path = buildSelectedPath(sessionId)
        if (path.isEmpty()) return emptyList()

        val historyMessages = path.takeWhile { it.id != currentMessageId }
        val contextSize = resolveTarget(_state.value.modelSettings).contextLength ?: 4096
        val maxOutput = resolveTarget(_state.value.modelSettings).maxTokens ?: 1024
        val budget = contextSize - maxOutput - 256
        var remaining = budget - estimateTokens(promptText)
        if (remaining <= 0) return emptyList()

        val selected = mutableListOf<LlmMessage>()
        for (message in historyMessages.asReversed()) {
            val text = historyText(message)
            val cost = estimateTokens(text)
            if (cost <= remaining) {
                selected.add(
                    LlmMessage(
                        text = text,
                        role = if (message.author == MessageAuthor.User) LlmMessageRole.User else LlmMessageRole.Assistant,
                        hasAttachments = message.attachments.isNotEmpty()
                    )
                )
                remaining -= cost
            } else if (selected.isEmpty()) {
                selected.add(
                    LlmMessage(
                        text = trimToBudget(text, remaining),
                        role = if (message.author == MessageAuthor.User) LlmMessageRole.User else LlmMessageRole.Assistant,
                        hasAttachments = message.attachments.isNotEmpty()
                    )
                )
                break
            } else {
                break
            }
        }

        return selected.reversed()
    }

    private fun historyText(message: ChatMessage): String {
        var text = message.text
        if (message.author == MessageAuthor.Assistant) {
            text = text.replace(Regex("<think>[\\s\\S]*?</think>"), "")
            text = text.replace(Regex("<todo_list>[\\s\\S]*?</todo_list>"), "")
        } else if (message.attachments.isNotEmpty()) {
            text += "\n\n[${message.attachments.size} attachments attached]"
        }
        return text.trim()
    }

    private fun trimToBudget(text: String, budget: Int): String {
        if (budget <= 0) return ""
        val maxChars = budget * 4
        return if (text.length <= maxChars) text else text.takeLast(maxChars)
    }

    private fun estimateTokens(text: String): Int {
        return max(1, text.length / 4)
    }

    private fun resolveTemperature(settings: ModelSettingsState): Float {
        val temperature = settings.temperature.trim().toFloatOrNull()
        return temperature?.takeIf { it >= 0f } ?: DEFAULT_TEMPERATURE
    }

    private fun resolveTarget(settings: ModelSettingsState): LlmModelTarget {
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

    private fun loadSessionsFromDb() {
        val sessions = chatRepository.listSessions().map { session ->
            val summary = sessionSummaries[session.id.lowercase()]
            if (!summary.isNullOrBlank()) {
                session.copy(title = summary)
            } else {
                session
            }
        }

        sessions.forEach { session ->
            messageStore.getOrPut(session.id) { mutableListOf() }
            branchSelections.getOrPut(session.id) { mutableMapOf() }
        }

        val currentSessionId = _state.value.chat.currentSessionId
        val sessionStillExists = currentSessionId != null && sessions.any { it.id == currentSessionId }

        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    sessions = sessions,
                    currentSessionId = if (sessionStillExists) currentSessionId else null
                )
            )
        }

        if (sessionStillExists && currentSessionId != null) {
            loadMessagesFromDb(currentSessionId)
            rebuildChatState(currentSessionId)
        } else {
            updateAttachmentDownloadState()
        }
    }

    private data class PromptResult(
        val text: String,
        val imageFiles: List<java.io.File>
    )

    companion object {
        private const val DEFAULT_MODEL_URL =
            "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf"
        private const val DEFAULT_MMPROJ_URL =
            "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
        private const val MEDIA_MARKER = "<__media__>"
        private const val DEFAULT_TEMPERATURE = 0.7f
        private const val SYSTEM_PROMPT =
            "You are a helpful assistant. Use Markdown **bold** to emphasize important terms and key points."
    }
}
