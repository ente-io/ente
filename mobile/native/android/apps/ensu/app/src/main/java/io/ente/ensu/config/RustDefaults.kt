package io.ente.ensu.config

import io.ente.ensu.config.ConfigDefaults
import io.ente.ensu.config.ConfigModelPreset
import io.ente.ensu.bindings.ConfigModelPreset as NativeConfigModelPreset
import io.ente.ensu.bindings.configDefaults
import io.ente.ensu.bindings.uniffiEnsureInitialized

object RustDefaults {
    fun load(): ConfigDefaults {
        uniffiEnsureInitialized()
        val defaults = configDefaults()
        return ConfigDefaults(
            mobileSystemPromptBody = defaults.mobileSystemPromptBody,
            desktopSystemPromptBody = defaults.desktopSystemPromptBody,
            systemPromptDatePlaceholder = defaults.systemPromptDatePlaceholder,
            sessionSummarySystemPrompt = defaults.sessionSummarySystemPrompt,
            mobileDefaultModel = defaults.mobileDefaultModel.toDomain(),
            mobileModelPresets = defaults.mobileModelPresets.map { it.toDomain() },
            desktopDefaultModel = defaults.desktopDefaultModel.toDomain(),
            desktopModelPresets = defaults.desktopModelPresets.map { it.toDomain() }
        )
    }
}

private fun NativeConfigModelPreset.toDomain(): ConfigModelPreset =
    ConfigModelPreset(
        id = id,
        title = title,
        url = url,
        mmprojUrl = mmprojUrl
    )
