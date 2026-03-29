package io.ente.ensu.domain.model

data class EnsuModelPreset(
    val id: String,
    val title: String,
    val url: String,
    val mmprojUrl: String?
)

data class EnsuDefaults(
    val mobileSystemPromptBody: String,
    val desktopSystemPromptBody: String,
    val systemPromptDatePlaceholder: String,
    val sessionSummarySystemPrompt: String,
    val mobileDefaultModel: EnsuModelPreset,
    val mobileModelPresets: List<EnsuModelPreset>,
    val desktopDefaultModel: EnsuModelPreset,
    val desktopModelPresets: List<EnsuModelPreset>
)
