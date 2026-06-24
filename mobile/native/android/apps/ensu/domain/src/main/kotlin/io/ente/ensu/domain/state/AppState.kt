package io.ente.ensu.domain.state

import io.ente.ensu.domain.model.AuthState


data class AppState(
    val auth: AuthState = AuthState(),
    val chat: ChatState = ChatState(),
    val developerSettings: DeveloperSettingsState = DeveloperSettingsState(),
    val modelSettings: ModelSettingsState = ModelSettingsState()
)
