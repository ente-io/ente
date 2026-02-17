@file:Suppress("PackageDirectoryMismatch")

package io.ente.ensu.components

import android.graphics.Rect
import android.view.ViewGroup
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import app.rive.runtime.kotlin.RiveAnimationView
import app.rive.runtime.kotlin.core.Alignment as RiveAlignment
import app.rive.runtime.kotlin.core.Fit
import app.rive.runtime.kotlin.core.Loop
import app.rive.runtime.kotlin.core.Rive
import io.ente.ensu.R

@Composable
fun ensuRiveAnimation(
    modifier: Modifier = Modifier,
    fit: Fit = Fit.CONTAIN,
    alignment: RiveAlignment = RiveAlignment.CENTER_LEFT,
    loop: Loop = Loop.LOOP,
    autoplay: Boolean = true,
    outroTrigger: Boolean = false,
    outroInputName: String = "outro",
    outroStateMachineName: String? = null,
    clipContent: Boolean = true
) {
    val context = LocalContext.current
    val appContext = context.applicationContext
    val riveView = remember(context, fit, alignment, loop, autoplay, clipContent) {
        Rive.init(appContext)
        RiveAnimationView(context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setRiveResource(
                resId = R.raw.ensu,
                autoplay = autoplay,
                fit = fit,
                alignment = alignment,
                loop = loop
            )
            addOnLayoutChangeListener { view, left, top, right, bottom, _, _, _, _ ->
                if (clipContent) {
                    val width = (right - left).coerceAtLeast(0)
                    val height = (bottom - top).coerceAtLeast(0)
                    view.clipBounds = Rect(0, 0, width, height)
                } else {
                    view.clipBounds = null
                }
            }
        }
    }
    var lastOutroTrigger by remember { mutableStateOf(false) }

    AndroidView(
        modifier = if (clipContent) modifier.clipToBounds() else modifier,
        factory = { riveView },
        update = { view ->
            view.layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            if (clipContent && view.width > 0 && view.height > 0) {
                view.clipBounds = Rect(0, 0, view.width, view.height)
            } else if (!clipContent) {
                view.clipBounds = null
            }
            if (outroTrigger && !lastOutroTrigger) {
                val stateMachineName = outroStateMachineName ?: view.stateMachines.firstOrNull()?.name
                if (stateMachineName != null) {
                    runCatching {
                        view.fireState(stateMachineName, outroInputName)
                    }
                }
            }
            lastOutroTrigger = outroTrigger
        }
    )
}
