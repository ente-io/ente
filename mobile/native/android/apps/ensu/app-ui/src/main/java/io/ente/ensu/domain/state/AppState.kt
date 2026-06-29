package io.ente.ensu.domain.state

data class AppState(
    val chat: ChatState = ChatState(),
    val developerSettings: DeveloperSettingsState = DeveloperSettingsState(),
    val modelSettings: ModelSettingsState = ModelSettingsState()
)
