package io.ente.ensu.domain.store

import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.logging.NoOpLogRepository
import io.ente.ensu.domain.model.AuthState
import io.ente.ensu.domain.model.ChatMessage
import io.ente.ensu.domain.model.ChatSession
import io.ente.ensu.domain.model.LogLevel
import io.ente.ensu.domain.model.MessageAuthor
import io.ente.ensu.domain.preferences.SessionPreferences
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.state.ChatState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class AppStore(
    private val sessionPreferences: SessionPreferences,
    private val clock: () -> Long = { System.currentTimeMillis() },
    private val logRepository: LogRepository = NoOpLogRepository
) {
    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    fun bootstrap(scope: CoroutineScope) {
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
                }
            }
        }
    }

    fun createNewSession(): String {
        val session = ChatSession(
            title = "New Chat",
            updatedAtMillis = clock()
        )
        _state.update { appState ->
            val updatedSessions = listOf(session) + appState.chat.sessions
            appState.copy(
                chat = appState.chat.copy(
                    sessions = updatedSessions,
                    currentSessionId = session.id,
                    messageText = "",
                    attachments = emptyList()
                )
            )
        }
        logRepository.log(LogLevel.Info, "Created new session")
        return session.id
    }

    fun selectSession(sessionId: String) {
        _state.update { appState ->
            appState.copy(chat = appState.chat.copy(currentSessionId = sessionId))
        }
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
        _state.update { appState ->
            val updatedSelections = appState.chat.branchSelections.toMutableMap()
            updatedSelections[messageId] = selectedIndex
            appState.copy(chat = appState.chat.copy(branchSelections = updatedSelections))
        }
    }

    fun sendMessage() {
        val currentState = _state.value
        val text = currentState.chat.messageText.trim()
        if (text.isEmpty()) return
        val sessionId = currentState.chat.currentSessionId ?: return
        val timestamp = clock()

        val userMessage = ChatMessage(
            sessionId = sessionId,
            author = MessageAuthor.User,
            text = text,
            timestampMillis = timestamp
        )
        val assistantMessage = ChatMessage(
            sessionId = sessionId,
            author = MessageAuthor.Assistant,
            text = "Thinking about: $text",
            timestampMillis = timestamp + 3000
        )

        _state.update { appState ->
            val updatedMessages = appState.chat.messages + userMessage + assistantMessage
            val updatedSessions = appState.chat.sessions.map { session ->
                if (session.id == sessionId) {
                    session.copy(
                        lastMessagePreview = text,
                        updatedAtMillis = timestamp
                    )
                } else {
                    session
                }
            }
            appState.copy(
                chat = appState.chat.copy(
                    messages = updatedMessages,
                    messageText = "",
                    sessions = updatedSessions
                )
            )
        }
        logRepository.log(LogLevel.Info, "Sent message", text)
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

    private fun seedSessions() {
        val now = clock()
        val sessions = listOf(
            ChatSession(title = "Ensu starter", lastMessagePreview = "Welcome to Ensū", updatedAtMillis = now - 3_600_000),
            ChatSession(title = "Project notes", lastMessagePreview = "Draft the plan", updatedAtMillis = now - 86_400_000)
        )
        _state.update { appState ->
            appState.copy(chat = appState.chat.copy(sessions = sessions, currentSessionId = sessions.first().id))
        }
    }
}
