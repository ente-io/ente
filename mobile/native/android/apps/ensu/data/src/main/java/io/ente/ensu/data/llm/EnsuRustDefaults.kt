package io.ente.ensu.data.llm

import io.ente.ensu.domain.model.EnsuDefaults
import io.ente.ensu.domain.model.EnsuModelPreset
import io.ente.labs.inference_rs.getEnsuDefaults
import io.ente.labs.inference_rs.uniffiEnsureInitialized

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

private fun io.ente.labs.inference_rs.EnsuModelPreset.toDomain(): EnsuModelPreset =
    EnsuModelPreset(
        id = id,
        title = title,
        url = url,
        mmprojUrl = mmprojUrl
    )
