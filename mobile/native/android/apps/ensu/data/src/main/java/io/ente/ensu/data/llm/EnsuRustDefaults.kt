package io.ente.ensu.data.llm

import io.ente.ensu.domain.model.EnsuDefaults
import io.ente.ensu.domain.model.EnsuModelPreset
import io.ente.ensu.bindings.EnsuModelPreset as NativeEnsuModelPreset
import io.ente.ensu.bindings.getEnsuDefaults
import io.ente.ensu.bindings.uniffiEnsureInitialized

object EnsuRustDefaults {
    fun load(): EnsuDefaults {
        uniffiEnsureInitialized()
        val defaults = getEnsuDefaults()
        return EnsuDefaults(
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

private fun NativeEnsuModelPreset.toDomain(): EnsuModelPreset =
    EnsuModelPreset(
        id = id,
        title = title,
        url = url,
        mmprojUrl = mmprojUrl
    )
