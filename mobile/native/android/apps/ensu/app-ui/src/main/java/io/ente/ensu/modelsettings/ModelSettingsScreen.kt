package io.ente.ensu.modelsettings

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import io.ente.ensu.domain.state.ModelSettingsState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModelSettingsScreen(
    state: ModelSettingsState,
    onSave: (ModelSettingsState) -> Unit,
    onReset: () -> Unit
) {
    val modelChoices = remember {
        listOf(
            ModelChoice(
                id = DEFAULT_OPTION_ID,
                title = DEFAULT_MODEL_NAME,
                url = DEFAULT_MODEL_URL,
                mmproj = DEFAULT_MMPROJ_URL,
                isDefault = true
            ),
            ModelChoice(
                id = "lfm-1.2b",
                title = "LFM 2.5 1.2B Instruct (Q4_0)",
                url = "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf"
            ),
            ModelChoice(
                id = "lfm-vl-1.6b",
                title = "LFM 2.5 VL 1.6B (Q4_0)",
                url = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
                mmproj = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
            ),
            ModelChoice(
                id = "qwen-2b",
                title = "Qwen 3.5 2B (Q8_0)",
                url = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true",
                mmproj = "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
            ),
            ModelChoice(
                id = CUSTOM_OPTION_ID,
                title = "Custom",
                isCustom = true
            )
        )
    }

    var selectedModelId by remember(state) {
        mutableStateOf(initialSelectionId(state, modelChoices))
    }
    var customModelUrl by remember(state) {
        mutableStateOf(
            if (state.useCustomModel && modelChoices.none { !it.isCustom && it.url == state.modelUrl }) {
                state.modelUrl
            } else {
                ""
            }
        )
    }
    var customMmprojUrl by remember(state) {
        mutableStateOf(
            if (state.useCustomModel && modelChoices.none { !it.isCustom && it.url == state.modelUrl }) {
                state.mmprojUrl
            } else {
                ""
            }
        )
    }
    var contextLength by remember(state) { mutableStateOf(state.contextLength) }
    var maxTokens by remember(state) { mutableStateOf(state.maxTokens) }
    var temperature by remember(state) { mutableStateOf(state.temperature) }
    var showAdvancedLimits by remember(state) {
        mutableStateOf(
            state.contextLength.isNotBlank() ||
                state.maxTokens.isNotBlank() ||
                state.temperature.isNotBlank()
        )
    }
    var isModelMenuExpanded by remember { mutableStateOf(false) }

    val selectedModel = modelChoices.firstOrNull { it.id == selectedModelId } ?: modelChoices.first()
    val isCustomSelected = selectedModel.isCustom
    val canSave = !isCustomSelected || customModelUrl.isNotBlank()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(EnsuSpacing.pageHorizontal.dp)
    ) {
        SectionHeader("Select model")
        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
        Text(
            text = "Choose a built-in model or switch to Custom.",
            style = EnsuTypography.small,
            color = EnsuColor.textMuted()
        )
        Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
        ExposedDropdownMenuBox(
            expanded = isModelMenuExpanded,
            onExpandedChange = { isModelMenuExpanded = !isModelMenuExpanded }
        ) {
            OutlinedTextField(
                value = selectedModel.title,
                onValueChange = {},
                readOnly = true,
                label = { Text("Model") },
                trailingIcon = {
                    ExposedDropdownMenuDefaults.TrailingIcon(expanded = isModelMenuExpanded)
                },
                modifier = Modifier
                    .menuAnchor()
                    .fillMaxWidth()
            )

            ExposedDropdownMenu(
                expanded = isModelMenuExpanded,
                onDismissRequest = { isModelMenuExpanded = false }
            ) {
                modelChoices.forEach { choice ->
                    DropdownMenuItem(
                        text = { Text(choice.title) },
                        onClick = {
                            selectedModelId = choice.id
                            isModelMenuExpanded = false
                            if (choice.isCustom) {
                                customModelUrl = ""
                                customMmprojUrl = ""
                            }
                        }
                    )
                }
            }
        }

        AnimatedVisibility(isCustomSelected) {
            Column {
                Spacer(modifier = Modifier.height(EnsuSpacing.lg.dp))
                Text(text = "Model .gguf URL", style = EnsuTypography.small, color = EnsuColor.textMuted())
                Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
                OutlinedTextField(
                    value = customModelUrl,
                    onValueChange = { customModelUrl = it },
                    placeholder = { Text(text = "https://huggingface.co/...") },
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))
                Text(text = "mmproj .gguf URL", style = EnsuTypography.small, color = EnsuColor.textMuted())
                Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
                OutlinedTextField(
                    value = customMmprojUrl,
                    onValueChange = { customMmprojUrl = it },
                    placeholder = { Text(text = "(optional for multimodal)") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.lg.dp))
        ExpandButton(
            title = "Advanced limits",
            expanded = showAdvancedLimits,
            collapsedHint = "Context length, output, temperature",
            onToggle = { showAdvancedLimits = !showAdvancedLimits }
        )
        AnimatedVisibility(showAdvancedLimits) {
            Column {
                Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
                Row {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = "Context length", style = EnsuTypography.small, color = EnsuColor.textMuted())
                        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
                        OutlinedTextField(
                            value = contextLength,
                            onValueChange = { contextLength = it },
                            placeholder = { Text(text = "8192") },
                            modifier = Modifier.fillMaxWidth(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                        )
                    }
                    Spacer(modifier = Modifier.width(EnsuSpacing.md.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = "Max output", style = EnsuTypography.small, color = EnsuColor.textMuted())
                        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
                        OutlinedTextField(
                            value = maxTokens,
                            onValueChange = { maxTokens = it },
                            placeholder = { Text(text = "2048") },
                            modifier = Modifier.fillMaxWidth(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))
                Text(text = "Temperature", style = EnsuTypography.small, color = EnsuColor.textMuted())
                Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
                OutlinedTextField(
                    value = temperature,
                    onValueChange = { temperature = it },
                    placeholder = { Text(text = "0.7") },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )

                Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
                Text(text = "Leave blank to use model defaults", style = EnsuTypography.small, color = EnsuColor.textMuted())
            }
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.xl.dp))
        HorizontalDivider()
        Spacer(modifier = Modifier.height(EnsuSpacing.lg.dp))

        Button(
            onClick = {
                val savedState = when {
                    selectedModel.isDefault -> state.copy(
                        useCustomModel = false,
                        modelUrl = "",
                        mmprojUrl = "",
                        contextLength = contextLength,
                        maxTokens = maxTokens,
                        temperature = temperature
                    )
                    selectedModel.isCustom -> state.copy(
                        useCustomModel = true,
                        modelUrl = customModelUrl,
                        mmprojUrl = customMmprojUrl,
                        contextLength = contextLength,
                        maxTokens = maxTokens,
                        temperature = temperature
                    )
                    else -> state.copy(
                        useCustomModel = true,
                        modelUrl = selectedModel.url.orEmpty(),
                        mmprojUrl = selectedModel.mmproj.orEmpty(),
                        contextLength = contextLength,
                        maxTokens = maxTokens,
                        temperature = temperature
                    )
                }
                onSave(savedState)
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = canSave,
            colors = ButtonDefaults.buttonColors(containerColor = EnsuColor.accent())
        ) {
            Text(text = "Save Model Settings", style = EnsuTypography.body)
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))

        TextButton(onClick = {
            onReset()
            selectedModelId = DEFAULT_OPTION_ID
            customModelUrl = ""
            customMmprojUrl = ""
            contextLength = ""
            maxTokens = ""
            temperature = ""
        }) {
            Text(text = "Reset to defaults", style = EnsuTypography.body, color = EnsuColor.action())
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))
        Text(
            text = "Changes apply the next time the model loads.",
            style = EnsuTypography.small,
            color = EnsuColor.textMuted()
        )
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(text = title, style = EnsuTypography.body)
}

@Composable
private fun ExpandButton(
    title: String,
    expanded: Boolean,
    collapsedHint: String,
    onToggle: () -> Unit
) {
    TextButton(onClick = onToggle, modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Text(text = title, style = EnsuTypography.body, color = EnsuColor.action())
            if (!expanded) {
                Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
                Text(text = collapsedHint, style = EnsuTypography.small, color = EnsuColor.textMuted())
            }
        }
    }
}

private data class ModelChoice(
    val id: String,
    val title: String,
    val url: String? = null,
    val mmproj: String? = null,
    val isDefault: Boolean = false,
    val isCustom: Boolean = false
)

private fun initialSelectionId(
    state: ModelSettingsState,
    choices: List<ModelChoice>
): String {
    if (!state.useCustomModel || state.modelUrl.isBlank()) return DEFAULT_OPTION_ID
    return choices.firstOrNull { !it.isCustom && it.url == state.modelUrl }?.id ?: CUSTOM_OPTION_ID
}

private const val DEFAULT_OPTION_ID = "default"
private const val CUSTOM_OPTION_ID = "custom"
private const val DEFAULT_MODEL_NAME = "Qwen 3.5 2B (Q8_0)"
private const val DEFAULT_MODEL_URL =
    "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-Q8_0.gguf?download=true"
private const val DEFAULT_MMPROJ_URL =
    "https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/mmproj-F16.gguf"
