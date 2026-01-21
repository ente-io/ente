@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package io.ente.ensu.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography

@Composable
fun AuthHeader(title: String, subtitle: String? = null) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.pageHorizontal.dp, vertical = EnsuSpacing.pageVertical.dp),
        verticalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
    ) {
        Text(text = title, style = EnsuTypography.h2Bold, color = EnsuColor.textPrimary())
        if (!subtitle.isNullOrBlank()) {
            Text(text = subtitle, style = EnsuTypography.body, color = EnsuColor.textMuted())
        }
    }
}

@Composable
fun AuthSubtitle(text: String) {
    Text(
        text = text,
        style = EnsuTypography.body,
        color = EnsuColor.textMuted(),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.pageHorizontal.dp)
    )
}

@Composable
fun LabeledTextField(
    label: String,
    hint: String,
    value: String,
    onValueChange: (String) -> Unit,
    keyboardType: KeyboardType = KeyboardType.Text,
    onSubmit: (() -> Unit)? = null
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.pageHorizontal.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(text = label, style = EnsuTypography.small, color = EnsuColor.textMuted())
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.fillMaxWidth(),
            textStyle = EnsuTypography.body,
            placeholder = { Text(text = hint, style = EnsuTypography.body) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = EnsuColor.fillFaint(),
                unfocusedContainerColor = EnsuColor.fillFaint(),
                focusedIndicatorColor = EnsuColor.fillFaint(),
                unfocusedIndicatorColor = EnsuColor.fillFaint(),
                cursorColor = EnsuColor.textPrimary()
            ),
            shape = RoundedCornerShape(EnsuCornerRadius.input.dp)
        )
    }
}

@Composable
fun PasswordTextField(
    label: String,
    hint: String,
    value: String,
    onValueChange: (String) -> Unit,
    showPassword: Boolean,
    onTogglePassword: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.pageHorizontal.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(text = label, style = EnsuTypography.small, color = EnsuColor.textMuted())
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.fillMaxWidth(),
            textStyle = EnsuTypography.body,
            placeholder = { Text(text = hint, style = EnsuTypography.body) },
            singleLine = true,
            visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            trailingIcon = {
                IconButton(onClick = onTogglePassword) {
                    Icon(
                        imageVector = if (showPassword) Icons.Outlined.VisibilityOff else Icons.Outlined.Visibility,
                        contentDescription = if (showPassword) "Hide password" else "Show password",
                        tint = EnsuColor.textMuted()
                    )
                }
            },
            colors = TextFieldDefaults.colors(
                focusedContainerColor = EnsuColor.fillFaint(),
                unfocusedContainerColor = EnsuColor.fillFaint(),
                focusedIndicatorColor = EnsuColor.fillFaint(),
                unfocusedIndicatorColor = EnsuColor.fillFaint(),
                cursorColor = EnsuColor.textPrimary()
            ),
            shape = RoundedCornerShape(EnsuCornerRadius.input.dp)
        )
    }
}

@Composable
fun CodeTextField(
    value: String,
    onValueChange: (String) -> Unit,
    maxLength: Int = 6,
    onComplete: ((String) -> Unit)? = null
) {
    val filtered = value.filter { it.isDigit() }.take(maxLength)
    if (filtered != value) {
        onValueChange(filtered)
    }

    OutlinedTextField(
        value = filtered,
        onValueChange = {
            val digits = it.filter { char -> char.isDigit() }.take(maxLength)
            onValueChange(digits)
            if (digits.length == maxLength) {
                onComplete?.invoke(digits)
            }
        },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = EnsuSpacing.pageHorizontal.dp),
        textStyle = TextStyle(
            fontSize = 28.sp,
            lineHeight = 32.sp,
            textAlign = TextAlign.Center,
            letterSpacing = 8.sp,
            color = EnsuColor.textPrimary()
        ),
        placeholder = {
            Text(
                text = "• • • • • •",
                modifier = Modifier.fillMaxWidth(),
                style = TextStyle(
                    fontSize = 28.sp,
                    lineHeight = 32.sp,
                    textAlign = TextAlign.Center,
                    letterSpacing = 8.sp,
                    color = EnsuColor.textMuted()
                )
            )
        },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        colors = TextFieldDefaults.colors(
            focusedContainerColor = EnsuColor.fillFaint(),
            unfocusedContainerColor = EnsuColor.fillFaint(),
            focusedIndicatorColor = EnsuColor.fillFaint(),
            unfocusedIndicatorColor = EnsuColor.fillFaint(),
            cursorColor = EnsuColor.textPrimary()
        ),
        shape = RoundedCornerShape(EnsuCornerRadius.input.dp)
    )
}

@Composable
fun PrimaryButton(
    text: String,
    isLoading: Boolean,
    isEnabled: Boolean,
    onClick: () -> Unit
) {
    val buttonTextStyle = EnsuTypography.body.copy(fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
    androidx.compose.material3.Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        enabled = isEnabled,
        colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = EnsuColor.accent()),
        contentPadding = PaddingValues(vertical = EnsuSpacing.buttonVertical.dp),
        shape = RoundedCornerShape(EnsuCornerRadius.button.dp)
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(18.dp),
                color = MaterialTheme.colorScheme.onPrimary,
                strokeWidth = 2.dp
            )
        } else {
            Text(text = text, style = buttonTextStyle, color = MaterialTheme.colorScheme.onPrimary)
        }
    }
}

@Composable
fun TextLink(text: String, onClick: () -> Unit) {
    TextButton(onClick = onClick) {
        Text(
            text = text,
            style = EnsuTypography.small,
            color = EnsuColor.accent()
        )
    }
}

@Composable
fun AuthScreen(
    content: @Composable () -> Unit,
    bottom: @Composable () -> Unit
) {
    val density = LocalDensity.current
    val imeBottom = WindowInsets.ime.getBottom(density)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(EnsuColor.backgroundBase())
    ) {
        content()
        Spacer(modifier = Modifier.weight(1f))
        if (imeBottom == 0) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = EnsuSpacing.pageHorizontal.dp)
                    .padding(top = EnsuSpacing.md.dp, bottom = EnsuSpacing.pageVertical.dp)
            ) {
                bottom()
            }
        }
    }
}
