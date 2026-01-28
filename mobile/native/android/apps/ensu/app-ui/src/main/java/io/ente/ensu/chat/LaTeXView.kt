package io.ente.ensu.chat

import android.view.ViewGroup
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.agog.mathdisplay.MTMathView
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuSpacing

@Composable
fun LaTeXView(latex: String, modifier: Modifier = Modifier) {
    val isDark = isSystemInDarkTheme()
    val textColor = if (isDark) EnsuColor.textPrimaryDark else EnsuColor.textPrimaryLight
    val paddingPx = with(LocalDensity.current) { EnsuSpacing.cardPadding.dp.roundToPx() }

    AndroidView(
        factory = { context ->
            MTMathView(context).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
                setPadding(paddingPx, paddingPx, paddingPx, paddingPx)
                MathViewCompat.setMathTextAlignment(
                    this,
                    MTMathView.MTTextAlignment.KMTTextAlignmentLeft
                )
                this.textColor = textColor.toArgb()
                this.fontSize = 16f * context.resources.displayMetrics.density
                this.latex = latex
            }
        },
        update = { view ->
            view.latex = latex
            view.textColor = textColor.toArgb()
            view.setPadding(paddingPx, paddingPx, paddingPx, paddingPx)
            MathViewCompat.setMathTextAlignment(
                view,
                MTMathView.MTTextAlignment.KMTTextAlignmentLeft
            )
        },
        modifier = modifier
    )
}
