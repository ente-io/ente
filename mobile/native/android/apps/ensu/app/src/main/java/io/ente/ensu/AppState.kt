package io.ente.ensu
import io.ente.ensu.llm.ModelSettingsState
import io.ente.ensu.settings.DeveloperSettingsState
import io.ente.ensu.chat.ChatState

data class AppState(
    val chat: ChatState = ChatState(),
    val developerSettings: DeveloperSettingsState = DeveloperSettingsState(),
    val modelSettings: ModelSettingsState = ModelSettingsState()
)
