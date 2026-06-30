package io.ente.ensu.llm

data class ModelSettingsState(
    val useCustomModel: Boolean = false,
    val modelUrl: String = "",
    val mmprojUrl: String = "",
    val contextLength: String = "",
    val maxTokens: String = "",
    val temperature: String = "",
    val isSaving: Boolean = false
)
