package io.ente.ensu.domain.store

import io.ente.ensu.domain.llm.LlmMessage
import io.ente.ensu.domain.llm.LlmModelTarget
import io.ente.ensu.domain.llm.LlmProvider
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.AttachmentType
import io.ente.ensu.domain.model.AuthState
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.model.MessageAuthor
import io.ente.ensu.domain.preferences.SessionPreferences
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.ModelSettingsState
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.logging.NoOpLogRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.max

class AppStore(
    private val sessionPreferences: SessionPreferences,
    private val llmProvider: LlmProvider,
    private val clock: () -> Long = { System.currentTimeMillis() },
    private val logRepository: LogRepository = NoOpLogRepository
) {
    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    private val messageStore = mutableMapOf<String, MutableList<ChatMessage>>()
    private val branchSelections = mutableMapOf<String, MutableMap<String, String>>()
    private var scope: CoroutineScope? = null
    private var generationJob: Job? = null
    private var stopRequested = false
    private var streamingParentId: String? = null

    fun bootstrap(scope: CoroutineScope) {
        this.scope = scope
        logRepository.log(LogLevel.Info, "Ensū started")

        if (_state.value.chat.sessions.isEmpty()) {
            seedSessions()
        }

        scope.launch {
            sessionPreferences.selectedSessionId.collectLatest { storedId ->
                if (storedId != null) {
                    _state.update { appState ->
                        if (appState.chat.sessions.any { it.id == storedId }) {
                            appState.copy(chat = appState.chat.copy(currentSessionId = storedId))
                        } else {
                            appState
                        }
                    }
                    rebuildChatState(storedId)
                }
            }
        }
    }

    fun createNewSession(): String {
        generationJob?.cancel()
        llmProvider.stopGeneration()
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

        val session = ChatSession(
            title = "New Chat",
            updatedAtMillis = clock()
        )
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
        rebuildChatState(session.id)
        logRepository.log(LogLevel.Info, "Created new session")
        return session.id
    }

    fun selectSession(sessionId: String) {
        generationJob?.cancel()
        llmProvider.stopGeneration()
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
        rebuildChatState(sessionId)
        logRepository.log(LogLevel.Info, "Selected session", sessionId)
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
        if (_state.value.chat.isGenerating || _state.value.chat.isDownloading) return

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

    fun cancelDownload() {
        generationJob?.cancel()
        llmProvider.cancelDownload()
        streamingParentId = null
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isGenerating = false,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = null,
                    downloadPercent = null,
                    downloadStatus = "Download cancelled"
                )
            )
        }
    }

    fun retryAssistantMessage(messageId: String) {
        val sessionId = _state.value.chat.currentSessionId ?: return
        val message = messageStore[sessionId]?.firstOrNull { it.id == messageId } ?: return
        if (message.author != MessageAuthor.Assistant) return
        val parentId = message.parentId ?: return
        val parent = messageStore[sessionId]?.firstOrNull { it.id == parentId } ?: return

        llmProvider.resetContext()
        startGeneration(sessionId, parent)
    }

    fun sendMessage() {
        val currentState = _state.value
        if (currentState.chat.isGenerating || currentState.chat.isDownloading) return
        val text = currentState.chat.messageText.trim()
        val attachments = currentState.chat.attachments
        if (text.isEmpty() && attachments.isEmpty()) return

        val sessionId = currentState.chat.currentSessionId ?: createNewSession()
        val timestamp = clock()

        val editingMessageId = currentState.chat.editingMessageId
        val parentId = if (editingMessageId != null) {
            val existing = messageStore[sessionId]?.firstOrNull { it.id == editingMessageId }
            existing?.parentId
        } else {
            buildSelectedPath(sessionId).lastOrNull()?.id
        }

        val userMessage = ChatMessage(
            sessionId = sessionId,
            parentId = parentId,
            author = MessageAuthor.User,
            text = text,
            timestampMillis = timestamp,
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
        logRepository.log(LogLevel.Info, "Sent message", text)
    }

    fun updateModelSettings(state: ModelSettingsState) {
        _state.update { appState ->
            appState.copy(modelSettings = state)
        }
    }

    fun resetModelSettings() {
        _state.update { appState ->
            appState.copy(modelSettings = ModelSettingsState())
        }
    }

    fun signIn(email: String) {
        _state.update { appState ->
            appState.copy(auth = AuthState(isLoggedIn = true, email = email))
        }
        logRepository.log(LogLevel.Info, "Signed in", email)
    }

    fun signOut() {
        _state.update { appState ->
            appState.copy(auth = AuthState())
        }
        logRepository.log(LogLevel.Info, "Signed out")
    }

    private fun startGeneration(sessionId: String, userMessage: ChatMessage) {
        val scope = scope ?: return
        generationJob?.cancel()
        stopRequested = false

        streamingParentId = userMessage.id
        _state.update { appState ->
            appState.copy(
                chat = appState.chat.copy(
                    isGenerating = true,
                    isDownloading = false,
                    streamingResponse = "",
                    streamingParentId = userMessage.id,
                    downloadPercent = null,
                    downloadStatus = null
                )
            )
        }
        rebuildChatState(sessionId)

        generationJob = scope.launch {
            val settings = _state.value.modelSettings
            val target = resolveTarget(settings)
            try {
                llmProvider.ensureModelReady(target) { progress ->
                    val downloading = (progress.percent in 0..99) || progress.status.contains("Loading", ignoreCase = true)
                    val finished = progress.status.contains("Ready", ignoreCase = true)
                    _state.update { appState ->
                        appState.copy(
                            chat = appState.chat.copy(
                                isDownloading = downloading && !finished,
                                downloadPercent = progress.percent.takeIf { it >= 0 },
                                downloadStatus = progress.status
                            )
                        )
                    }
                }
            } catch (err: Throwable) {
                val cancelled = err is kotlinx.coroutines.CancellationException ||
                    err.message?.contains("cancel", ignoreCase = true) == true
                streamingParentId = null
                _state.update { appState ->
                    appState.copy(
                        chat = appState.chat.copy(
                            isGenerating = false,
                            isDownloading = false,
                            streamingParentId = null,
                            downloadPercent = null,
                            downloadStatus = if (cancelled) "Download cancelled" else null
                        )
                    )
                }
                if (!cancelled) {
                    logRepository.log(LogLevel.Error, "Model load failed", err.message ?: "")
                }
                return@launch
            }

            val prompt = buildPrompt(userMessage.text, userMessage.attachments)
            val history = buildHistory(sessionId, prompt.text, userMessage.id)
            val llmMessages = history + LlmMessage(
                text = prompt.text,
                isUser = true,
                hasAttachments = userMessage.attachments.isNotEmpty()
            )

            val buffer = StringBuilder()
            var tokenCount = 0

            try {
                val summary = llmProvider.generateChat(
                    target = target,
                    messages = llmMessages,
                    imageFiles = prompt.imageFiles,
                    temperature = 0.7f,
                    maxTokens = target.maxTokens ?: 1024
                ) { token ->
                    buffer.append(token)
                    tokenCount += estimateTokens(token)
                    _state.update { appState ->
                        appState.copy(chat = appState.chat.copy(streamingResponse = buffer.toString()))
                    }
                }

                finishGeneration(sessionId, userMessage, buffer, tokenCount, summary.totalTimeMs, false)
            } catch (err: Throwable) {
                val interrupted = stopRequested || err.message?.contains("cancel", ignoreCase = true) == true
                finishGeneration(sessionId, userMessage, buffer, tokenCount, null, interrupted)
                if (!interrupted) {
                    logRepository.log(LogLevel.Error, "Generation failed", err.message ?: "")
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
        interrupted: Boolean
    ) {
        val finalText = buffer.toString().trim()
        if (finalText.isNotEmpty()) {
            val tokensPerSecond = if (totalTimeMs != null && totalTimeMs > 0) {
                tokenCount.toDouble() / (totalTimeMs / 1000.0)
            } else null

            val assistantMessage = ChatMessage(
                sessionId = sessionId,
                parentId = parentMessage.id,
                author = MessageAuthor.Assistant,
                text = finalText,
                timestampMillis = clock(),
                isInterrupted = interrupted,
                tokensPerSecond = tokensPerSecond
            )

            messageStore.getOrPut(sessionId) { mutableListOf() }.add(assistantMessage)
            updateSelectionForParent(sessionId, parentMessage.id, assistantMessage.id)
            updateCurrentSessionPreview(sessionId, finalText, assistantMessage.timestampMillis)
        }

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
    }

    private fun updateCurrentSessionPreview(sessionId: String, preview: String, timestamp: Long) {
        _state.update { appState ->
            val updatedSessions = appState.chat.sessions.map { session ->
                if (session.id == sessionId) {
                    session.copy(lastMessagePreview = preview, updatedAtMillis = timestamp)
                } else {
                    session
                }
            }
            appState.copy(chat = appState.chat.copy(sessions = updatedSessions))
        }
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
                selected.add(LlmMessage(text, message.author == MessageAuthor.User, message.attachments.isNotEmpty()))
                remaining -= cost
            } else if (selected.isEmpty()) {
                selected.add(LlmMessage(trimToBudget(text, remaining), message.author == MessageAuthor.User, message.attachments.isNotEmpty()))
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

    private fun seedSessions() {
        val now = clock()
        val session = ChatSession(title = "New Chat", lastMessagePreview = null, updatedAtMillis = now)
        messageStore[session.id] = mutableListOf()
        branchSelections[session.id] = mutableMapOf()
        _state.update { appState ->
            appState.copy(chat = appState.chat.copy(sessions = listOf(session), currentSessionId = session.id))
        }
        rebuildChatState(session.id)
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
    }
}
