package io.ente.ensu.config

data class ConfigModelPreset(
    val id: String,
    val title: String,
    val url: String,
    val mmprojUrl: String?
)

data class ConfigDefaults(
    val mobileSystemPromptBody: String,
    val desktopSystemPromptBody: String,
    val systemPromptDatePlaceholder: String,
    val sessionSummarySystemPrompt: String,
    val mobileDefaultModel: ConfigModelPreset,
    val mobileModelPresets: List<ConfigModelPreset>,
    val desktopDefaultModel: ConfigModelPreset,
    val desktopModelPresets: List<ConfigModelPreset>
)
