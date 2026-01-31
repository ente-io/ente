package io.ente.ensu.domain.store

import io.ente.ensu.domain.chat.ChatRepository
import io.ente.ensu.domain.chat.ChatSyncRepository
import io.ente.ensu.domain.llm.LlmProvider
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.logging.NoOpLogRepository
import io.ente.ensu.domain.model.Attachment
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.preferences.SessionPreferences
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.ModelSettingsState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class AppStore(
    private val sessionPreferences: SessionPreferences,
    private val chatRepository: ChatRepository,
    private val chatSyncRepository: ChatSyncRepository? = null,
    private val llmProvider: LlmProvider,
    private val clock: () -> Long = { System.currentTimeMillis() },
    private val logRepository: LogRepository = NoOpLogRepository
) {
    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    private val messageStore = mutableMapOf<String, MutableList<ChatMessage>>()
    private val attachmentActions = AttachmentStoreActions(_state, chatSyncRepository, messageStore)
    private val modelSettingsActions = ModelSettingsActions(_state, llmProvider, logRepository)
    private val syncActions = SyncStoreActions(_state, chatSyncRepository, logRepository)
    private val chatActions = ChatStoreActions(
        state = _state,
        sessionPreferences = sessionPreferences,
        chatRepository = chatRepository,
        llmProvider = llmProvider,
        clock = clock,
        logRepository = logRepository,
        messageStore = messageStore,
        attachmentActions = attachmentActions,
        syncActions = syncActions,
        modelSettingsActions = modelSettingsActions
    )
    private val authActions = AuthStoreActions(_state, logRepository) {
        syncActions.syncNow()
    }

    init {
        syncActions.setReloadSessions { chatActions.loadSessionsFromDb() }
    }

    fun bootstrap(scope: CoroutineScope) {
        chatActions.setScope(scope)
        attachmentActions.setScope(scope)
        syncActions.setScope(scope)
        modelSettingsActions.setScope(scope)
        chatActions.bootstrap(scope)
        modelSettingsActions.refreshModelDownloadInfo()
    }

    fun createNewSession(): String = chatActions.createNewSession()

    fun startNewSessionDraft() = chatActions.startNewSessionDraft()

    fun selectSession(sessionId: String) = chatActions.selectSession(sessionId)

    fun deleteSession(sessionId: String) = chatActions.deleteSession(sessionId)

    fun persistSelectedSession(scope: CoroutineScope, sessionId: String?) =
        chatActions.persistSelectedSession(scope, sessionId)

    fun updateMessageText(value: String) = chatActions.updateMessageText(value)

    fun updateBranchSelection(messageId: String, selectedIndex: Int) =
        chatActions.updateBranchSelection(messageId, selectedIndex)

    fun beginEditing(messageId: String) = chatActions.beginEditing(messageId)

    fun cancelEditing() = chatActions.cancelEditing()

    fun setAttachmentProcessing(isProcessing: Boolean) =
        attachmentActions.setAttachmentProcessing(isProcessing)

    fun addAttachment(attachment: Attachment) = attachmentActions.addAttachment(attachment)

    fun removeAttachment(attachment: Attachment) = attachmentActions.removeAttachment(attachment)

    fun stopGeneration() = chatActions.stopGeneration()

    fun startModelDownload(userInitiated: Boolean = true) =
        modelSettingsActions.startModelDownload(userInitiated)

    fun cancelDownload() {
        chatActions.cancelGenerationForDownload()
        modelSettingsActions.cancelModelDownload()
    }

    fun retryAssistantMessage(messageId: String) = chatActions.retryAssistantMessage(messageId)

    fun sendMessage() = chatActions.sendMessage()

    fun confirmOverflowTrim() = chatActions.confirmOverflowTrim()

    fun cancelOverflowDialog() = chatActions.cancelOverflowDialog()

    fun updateModelSettings(state: ModelSettingsState) =
        modelSettingsActions.updateModelSettings(state)

    fun resetModelSettings() = modelSettingsActions.resetModelSettings()

    fun signIn(email: String) = authActions.signIn(email)

    fun signOut() = authActions.signOut()

    fun syncNow(
        onSuccess: (() -> Unit)? = null,
        onError: ((String) -> Unit)? = null
    ) = syncActions.syncNow(onSuccess, onError)

    fun cancelAttachmentDownload(attachmentId: String) =
        attachmentActions.cancelAttachmentDownload(attachmentId)
}
