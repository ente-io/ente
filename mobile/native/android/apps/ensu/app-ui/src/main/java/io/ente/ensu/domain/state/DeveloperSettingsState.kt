package io.ente.ensu.domain.state

data class DeveloperSettingsState(
    val isAdvancedUnlocked: Boolean = false,
    val systemPrompt: String = ""
)
