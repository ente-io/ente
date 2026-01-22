package io.ente.ensu.modelsettings

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
import androidx.compose.material3.Card
import androidx.compose.material3.Divider
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

@Composable
fun ModelSettingsScreen(
    state: ModelSettingsState,
    onSave: (ModelSettingsState) -> Unit,
    onReset: () -> Unit
) {
    var modelUrl by remember(state) { mutableStateOf(state.modelUrl) }
    var mmprojUrl by remember(state) { mutableStateOf(state.mmprojUrl) }
    var contextLength by remember(state) { mutableStateOf(state.contextLength) }
    var maxTokens by remember(state) { mutableStateOf(state.maxTokens) }
    var temperature by remember(state) { mutableStateOf(state.temperature) }

    val suggestedModels = listOf(
        SuggestedModel(
            title = "Qwen3-VL 2B Instruct (Q4_K_M)",
            subtitle = "Requires mmproj",
            url = "https://huggingface.co/LiquidAI/Qwen3-VL-2B-Instruct-GGUF/resolve/main/Qwen3-VL-2B-Instruct-Q4_K_M.gguf",
            mmproj = "https://huggingface.co/LiquidAI/Qwen3-VL-2B-Instruct-GGUF/resolve/main/mmproj-qwen3-vl-2b.gguf"
        ),
        SuggestedModel(
            title = "LFM 2.5 1.2B Instruct (Q4_0)",
            subtitle = "Smallest download",
            url = "https://huggingface.co/LiquidAI/LFM2.5-1.2B-GGUF/resolve/main/LFM2.5-1.2B-Q4_0.gguf",
            mmproj = null
        ),
        SuggestedModel(
            title = "LFM 2.5 VL 1.6B (Q4_0)",
            subtitle = "Requires mmproj",
            url = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf",
            mmproj = "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/mmproj-LFM2.5-VL-1.6b-Q8_0.gguf"
        ),
        SuggestedModel(
            title = "Llama 3.2 1B Instruct (Q4_K_M)",
            subtitle = "Fastest load",
            url = "https://huggingface.co/meta-llama/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
            mmproj = null
        )
    )

    val isCustomSelected = state.useCustomModel && modelUrl.isNotBlank()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(EnsuSpacing.pageHorizontal.dp)
    ) {
        SectionHeader("Selected model")
        val selectedLabel = if (isCustomSelected) "Custom model" else "Default model"
        Text(text = selectedLabel, style = EnsuTypography.body)
        if (isCustomSelected) {
            Text(text = modelUrl, style = EnsuTypography.small, color = EnsuColor.textMuted())
        } else {
            Text(text = DEFAULT_MODEL_NAME, style = EnsuTypography.small, color = EnsuColor.textMuted())
            Text(text = DEFAULT_MODEL_URL, style = EnsuTypography.mini, color = EnsuColor.textMuted())
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.xl.dp))
        SectionHeader("Custom Hugging Face model")
        Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))

        Text(text = "Direct .gguf file URL", style = EnsuTypography.small, color = EnsuColor.textMuted())
        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
        OutlinedTextField(
            value = modelUrl,
            onValueChange = { modelUrl = it },
            placeholder = { Text(text = "https://huggingface.co/...") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))

        Text(text = "mmproj .gguf file URL", style = EnsuTypography.small, color = EnsuColor.textMuted())
        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
        OutlinedTextField(
            value = mmprojUrl,
            onValueChange = { mmprojUrl = it },
            placeholder = { Text(text = "(optional for multimodal)") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(EnsuSpacing.lg.dp))

        Text(text = "Suggested models:", style = EnsuTypography.small, color = EnsuColor.textMuted())
        suggestedModels.forEach { model ->
            SuggestedModelCard(
                title = model.title,
                subtitle = model.subtitle,
                onFill = {
                    modelUrl = model.url
                    mmprojUrl = model.mmproj.orEmpty()
                }
            )
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.xl.dp))
        SectionHeader("Custom limits (optional)")
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

        Spacer(modifier = Modifier.height(EnsuSpacing.xl.dp))
        Divider()
        Spacer(modifier = Modifier.height(EnsuSpacing.lg.dp))

        Button(
            onClick = {
                onSave(
                    state.copy(
                        useCustomModel = true,
                        modelUrl = modelUrl,
                        mmprojUrl = mmprojUrl,
                        contextLength = contextLength,
                        maxTokens = maxTokens,
                        temperature = temperature
                    )
                )
            },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = EnsuColor.accent())
        ) {
            Text(text = "Use Custom Model", style = EnsuTypography.body)
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))

        TextButton(onClick = {
            onReset()
            modelUrl = ""
            mmprojUrl = ""
            contextLength = ""
            maxTokens = ""
            temperature = ""
        }) {
            Text(text = "Use Default Model", style = EnsuTypography.body, color = EnsuColor.accent())
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))
        Text(
            text = "Changes require redownloading the model.",
            style = EnsuTypography.small,
            color = EnsuColor.textMuted()
        )
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(text = title, style = EnsuTypography.h3Bold)
}

@Composable
private fun SuggestedModelCard(title: String, subtitle: String, onFill: () -> Unit) {
    Card(modifier = Modifier
        .fillMaxWidth()
        .padding(vertical = EnsuSpacing.xs.dp)
    ) {
        Column(modifier = Modifier.padding(EnsuSpacing.md.dp)) {
            Text(text = title, style = EnsuTypography.body)
            Text(text = subtitle, style = EnsuTypography.small, color = EnsuColor.textMuted())
            TextButton(onClick = onFill) {
                Text(text = "Fill", style = EnsuTypography.small, color = EnsuColor.accent())
            }
        }
    }
}

private data class SuggestedModel(
    val title: String,
    val subtitle: String,
    val url: String,
    val mmproj: String?
)

private const val DEFAULT_MODEL_NAME = "LFM 2.5 VL 1.6B (Q4_0)"
private const val DEFAULT_MODEL_URL =
    "https://huggingface.co/LiquidAI/LFM2.5-VL-1.6B-GGUF/resolve/main/LFM2.5-VL-1.6B-Q4_0.gguf"
