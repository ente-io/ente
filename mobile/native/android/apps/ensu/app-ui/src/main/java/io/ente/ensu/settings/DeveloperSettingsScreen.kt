package io.ente.ensu.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.ente.ensu.auth.PrimaryButton
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

@Composable
fun DeveloperSettingsScreen(
    authService: EnsuAuthService,
    currentEndpointFlow: Flow<String>,
    onSaved: () -> Unit
) {
    val currentEndpoint by currentEndpointFlow.collectAsState(initial = "https://api.ente.io")
    var endpointInput by remember { mutableStateOf("") }
    var isSaving by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    val isSavable = endpointInput.trim().isNotEmpty() && !isSaving

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(EnsuSpacing.pageHorizontal.dp)
    ) {
        Text(text = "Endpoint configuration", style = EnsuTypography.h3Bold, color = EnsuColor.textPrimary())
        Spacer(modifier = Modifier.height(EnsuSpacing.md.dp))

        Text(text = "Server endpoint", style = EnsuTypography.small, color = EnsuColor.textMuted())
        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
        OutlinedTextField(
            value = endpointInput,
            onValueChange = { endpointInput = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text(text = currentEndpoint, style = EnsuTypography.body) },
            singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = EnsuColor.fillFaint(),
                unfocusedContainerColor = EnsuColor.fillFaint(),
                focusedIndicatorColor = EnsuColor.fillFaint(),
                unfocusedIndicatorColor = EnsuColor.fillFaint()
            ),
            shape = RoundedCornerShape(EnsuCornerRadius.input.dp)
        )
        Spacer(modifier = Modifier.height(EnsuSpacing.xs.dp))
        Text(
            text = "Current endpoint: $currentEndpoint",
            style = EnsuTypography.mini,
            color = EnsuColor.textMuted()
        )

        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(EnsuSpacing.sm.dp))
            Text(
                text = errorMessage.orEmpty(),
                style = EnsuTypography.small,
                color = EnsuColor.error
            )
        }

        Spacer(modifier = Modifier.height(EnsuSpacing.lg.dp))

        PrimaryButton(
            text = "Save",
            isLoading = isSaving,
            isEnabled = isSavable
        ) {
            scope.launch {
                if (isSaving) return@launch
                isSaving = true
                errorMessage = null
                val result = authService.setEndpoint(endpointInput)
                if (result.isSuccess) {
                    endpointInput = ""
                    onSaved()
                } else {
                    errorMessage = "Unable to reach the server at the provided endpoint."
                }
                isSaving = false
            }
        }
    }
}
