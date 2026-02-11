package io.ente.ensu.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import app.rive.runtime.kotlin.RiveAnimationView
import app.rive.runtime.kotlin.core.Alignment as RiveAlignment
import app.rive.runtime.kotlin.core.Fit
import app.rive.runtime.kotlin.core.Loop
import app.rive.runtime.kotlin.core.Rive
import io.ente.ensu.R

@Composable
fun EnsuRiveAnimation(
    modifier: Modifier = Modifier,
    fit: Fit = Fit.CONTAIN,
    alignment: RiveAlignment = RiveAlignment.CENTER_LEFT,
    loop: Loop = Loop.LOOP,
    autoplay: Boolean = true
) {
    val context = LocalContext.current
    val appContext = context.applicationContext
    val riveView = remember(context, fit, alignment, loop, autoplay) {
        Rive.init(appContext)
        RiveAnimationView(context).apply {
            setRiveResource(
                resId = R.raw.ensu,
                autoplay = autoplay,
                fit = fit,
                alignment = alignment,
                loop = loop
            )
        }
    }

    AndroidView(
        modifier = modifier,
        factory = { riveView },
        update = { }
    )
}
