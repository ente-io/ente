@file:Suppress("PackageDirectoryMismatch")

package io.ente.ensu.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuTypography
import kotlinx.coroutines.delay

@Composable
fun GeneratingDotsIndicator(
    modifier: Modifier = Modifier,
    isAnimating: Boolean = true,
    alignment: Alignment = Alignment.Center,
    textStyle: TextStyle = EnsuTypography.message,
    color: Color = EnsuColor.textMuted()
) {
    var dotCount by remember { mutableIntStateOf(1) }

    LaunchedEffect(isAnimating) {
        if (!isAnimating) {
            dotCount = 1
            return@LaunchedEffect
        }

        while (true) {
            delay(420)
            dotCount = if (dotCount == 3) 1 else dotCount + 1
        }
    }

    Box(modifier = modifier, contentAlignment = alignment) {
        Text(
            text = ".".repeat(dotCount),
            style = textStyle,
            color = color,
            fontFamily = FontFamily.Monospace,
            modifier = Modifier.widthIn(min = 24.dp)
        )
    }
}
