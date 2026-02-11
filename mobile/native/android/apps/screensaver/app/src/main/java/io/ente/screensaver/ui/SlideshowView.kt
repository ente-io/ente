package io.ente.screensaver.ui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Animatable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.text.format.DateFormat
import android.util.AttributeSet
import android.view.LayoutInflater
import android.widget.FrameLayout
import android.widget.ImageView
import coil.ImageLoader
import coil.request.Disposable
import coil.request.ImageRequest
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DataSource as GlideDataSource
import com.bumptech.glide.load.engine.GlideException
import com.bumptech.glide.request.RequestListener
import com.bumptech.glide.request.target.Target
import com.github.penfeizhou.animation.apng.APNGDrawable
import com.github.penfeizhou.animation.avif.AVIFDrawable
import com.github.penfeizhou.animation.webp.WebPDrawable
import com.awxkee.jxlcoder.JxlAnimatedImage
import com.awxkee.jxlcoder.JxlCoder
import com.awxkee.jxlcoder.JxlToneMapper
import com.awxkee.jxlcoder.PreferredColorConfig
import com.awxkee.jxlcoder.ScaleMode
import com.squareup.picasso.Callback
import com.squareup.picasso.Picasso
import io.ente.screensaver.databinding.ViewSlideshowBinding
import io.ente.screensaver.diagnostics.AppLog
import io.ente.screensaver.diagnostics.redactedForLog
import io.ente.screensaver.ente.EnteImageCache
import io.ente.screensaver.imageloading.ImageFormatClassifier
import io.ente.screensaver.prefs.FitMode
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.util.Date
import kotlin.coroutines.resume
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout

class SlideshowView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    private val binding = ViewSlideshowBinding.inflate(LayoutInflater.from(context), this, true)

    private var visibleImage: ImageView = binding.imageCurrent
    private var hiddenImage: ImageView = binding.imageNext

    private var activeRequest: Disposable? = null
    private val scope = MainScope()
    private var activeSpecialDecodeJob: Job? = null

    private var clockEnabled: Boolean = false
    private val clockTicker: Runnable = object : Runnable {
        override fun run() {
            if (!clockEnabled) return
            binding.textClock.text = DateFormat.getTimeFormat(context).format(Date())
            postDelayed(this, 1000L)
        }
    }

    fun setFitMode(fitMode: FitMode) {
        val scaleType = when (fitMode) {
            FitMode.CROP -> ImageView.ScaleType.CENTER_CROP
            FitMode.FIT -> ImageView.ScaleType.FIT_CENTER
        }
        binding.imageCurrent.scaleType = scaleType
        binding.imageNext.scaleType = scaleType
    }

    fun setOverlayMode(mode: io.ente.screensaver.prefs.OverlayMode) {
        // Calculate 40% of screen width dynamically for max width
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val maxWidth = (screenWidth * 0.4).toInt()
        
        // Apply max width to both clock and description/message
        binding.textClock.maxWidth = maxWidth
        binding.textDescription.maxWidth = maxWidth
        binding.textMessage.maxWidth = maxWidth
        
        when (mode) {
            io.ente.screensaver.prefs.OverlayMode.NORMAL -> {
                // Clock on right, description on left (default layout order)
                binding.bottomOverlay.visibility = VISIBLE
                clockEnabled = true
                binding.textClock.visibility = VISIBLE
                removeCallbacks(clockTicker)
                post(clockTicker)
                
                // Set text alignment for normal mode (left-aligned text)
                binding.textDescription.gravity = android.view.Gravity.START
                binding.textMessage.gravity = android.view.Gravity.START
                
                // Rebuild layout: description container, spacer, clock
                binding.bottomOverlay.removeAllViews()
                binding.bottomOverlay.addView(binding.descriptionContainer)
                
                // Add spacer to push clock to the right
                val spacer = android.view.View(context)
                val params = android.widget.LinearLayout.LayoutParams(0, 0)
                params.weight = 1f
                spacer.layoutParams = params
                binding.bottomOverlay.addView(spacer)
                
                binding.bottomOverlay.addView(binding.textClock)
            }
            io.ente.screensaver.prefs.OverlayMode.ALTERNATE -> {
                // Clock on left, description on right (swapped order)
                binding.bottomOverlay.visibility = VISIBLE
                clockEnabled = true
                binding.textClock.visibility = VISIBLE
                removeCallbacks(clockTicker)
                post(clockTicker)
                
                // Set text alignment for alternate mode (right-aligned text)
                binding.textDescription.gravity = android.view.Gravity.END
                binding.textMessage.gravity = android.view.Gravity.END
                
                // Rebuild layout: clock, spacer, description container
                binding.bottomOverlay.removeAllViews()
                binding.bottomOverlay.addView(binding.textClock)
                
                // Add spacer to push description to the right
                val spacer = android.view.View(context)
                val params = android.widget.LinearLayout.LayoutParams(0, 0)
                params.weight = 1f
                spacer.layoutParams = params
                binding.bottomOverlay.addView(spacer)
                
                binding.bottomOverlay.addView(binding.descriptionContainer)
            }
            io.ente.screensaver.prefs.OverlayMode.DISABLE -> {
                // Hide the entire overlay
                binding.bottomOverlay.visibility = GONE
                clockEnabled = false
                binding.textClock.visibility = GONE
                removeCallbacks(clockTicker)
            }
        }
    }

    fun showMessage(message: String?) {
        if (message.isNullOrBlank()) {
            // Fade out and hide
            if (binding.textMessage.visibility == VISIBLE) {
                binding.textMessage.animate()
                    .alpha(0f)
                    .setDuration(300L)
                    .withEndAction {
                        binding.textMessage.text = ""
                        binding.textMessage.visibility = GONE
                        binding.textMessage.alpha = 1f
                        updateOverlayVisibility()
                    }
                    .start()
            }
        } else {
            // Set text and fade in
            val wasVisible = binding.textMessage.visibility == VISIBLE
            binding.textMessage.text = message
            if (!wasVisible) {
                binding.textMessage.alpha = 0f
                binding.textMessage.visibility = VISIBLE
                updateOverlayVisibility()
                binding.textMessage.animate()
                    .alpha(1f)
                    .setDuration(300L)
                    .start()
            }
        }
    }

    fun setDescription(description: String?) {
        if (description.isNullOrBlank()) {
            // Fade out and hide
            if (binding.textDescription.visibility == VISIBLE) {
                binding.textDescription.animate()
                    .alpha(0f)
                    .setDuration(300L)
                    .withEndAction {
                        binding.textDescription.text = ""
                        binding.textDescription.visibility = GONE
                        binding.textDescription.alpha = 1f
                        updateOverlayVisibility()
                    }
                    .start()
            }
        } else {
            // Set text and fade in
            val wasVisible = binding.textDescription.visibility == VISIBLE
            binding.textDescription.text = description
            if (!wasVisible) {
                binding.textDescription.alpha = 0f
                binding.textDescription.visibility = VISIBLE
                updateOverlayVisibility()
                binding.textDescription.animate()
                    .alpha(1f)
                    .setDuration(300L)
                    .start()
            }
        }
    }

    private fun updateOverlayVisibility() {
        val hasContent = binding.textClock.visibility == VISIBLE ||
                         binding.textMessage.visibility == VISIBLE ||
                         binding.textDescription.visibility == VISIBLE

        if (hasContent && binding.bottomOverlay.alpha == 0f) {
            // Fade in overlay
            binding.bottomOverlay.animate()
                .alpha(1f)
                .setDuration(300L)
                .start()
        } else if (!hasContent && binding.bottomOverlay.alpha == 1f) {
            // Fade out overlay
            binding.bottomOverlay.animate()
                .alpha(0f)
                .setDuration(300L)
                .start()
        }
    }

    fun clear() {
        activeRequest?.dispose()
        activeRequest = null
        activeSpecialDecodeJob?.cancel()
        activeSpecialDecodeJob = null
        Glide.with(this).clear(hiddenImage)
        Glide.with(this).clear(visibleImage)
        Picasso.get().cancelRequest(hiddenImage)
        Picasso.get().cancelRequest(visibleImage)

        visibleImage.animate().cancel()
        hiddenImage.animate().cancel()
        binding.textMessage.animate().cancel()
        binding.textDescription.animate().cancel()
        binding.bottomOverlay.animate().cancel()

        visibleImage.setImageDrawable(null)
        hiddenImage.setImageDrawable(null)
        visibleImage.alpha = 1f
        hiddenImage.alpha = 0f
        binding.textMessage.alpha = 1f
        binding.textDescription.alpha = 1f
        binding.bottomOverlay.alpha = 1f

        removeCallbacks(clockTicker)
    }

    suspend fun showNext(
        uri: Uri,
        imageLoader: ImageLoader,
        transitionMs: Long,
    ): Boolean = suspendCancellableCoroutine { cont ->
        activeRequest?.dispose()
        activeRequest = null
        activeSpecialDecodeJob?.cancel()
        activeSpecialDecodeJob = null
        Glide.with(this).clear(hiddenImage)
        Picasso.get().cancelRequest(hiddenImage)

        visibleImage.animate().cancel()
        hiddenImage.animate().cancel()

        hiddenImage.alpha = 0f
        val isFirstImage = visibleImage.drawable == null
        val initialUri = resolveFallbackUri(uri)
        val format = detectFormat(initialUri, uri)
        val loadPlan = loadPlanFor(format)
        AppLog.info("Slideshow", "Load plan $loadPlan for ${uri.redactedForLog()} (family=${format.family})")

        fun finishSuccess() {
            if (!cont.isActive) return

            if (transitionMs <= 0L || isFirstImage) {
                val oldVisible = visibleImage
                visibleImage = hiddenImage
                hiddenImage = oldVisible

                visibleImage.alpha = 1f
                hiddenImage.alpha = 0f
                hiddenImage.setImageDrawable(null)

                if (cont.isActive) {
                    cont.resume(true)
                }
                return
            }

            hiddenImage.animate()
                .alpha(1f)
                .setDuration(transitionMs)
                .start()

            visibleImage.animate()
                .alpha(0f)
                .setDuration(transitionMs)
                .withEndAction {
                    val oldVisible = visibleImage
                    visibleImage = hiddenImage
                    hiddenImage = oldVisible

                    hiddenImage.setImageDrawable(null)
                    hiddenImage.alpha = 0f

                    if (cont.isActive) {
                        cont.resume(true)
                    }
                }
                .start()
        }

        fun finishFailure() {
            if (cont.isActive) {
                cont.resume(false)
            }
        }

        fun startCoil(onFailure: () -> Unit) {
            if (!cont.isActive) return
            val loadUri = resolveFallbackUri(uri)
            val request = ImageRequest.Builder(context)
                .data(loadUri)
                .allowHardware(false)
                .allowRgb565(false)
                .bitmapConfig(Bitmap.Config.ARGB_8888)
                .crossfade(false)
                .target(hiddenImage)
                .listener(
                    onSuccess = { _, _ ->
                        finishSuccess()
                    },
                    onError = { _, result ->
                        AppLog.error("Slideshow", "Coil failed to load ${uri.redactedForLog()}", result.throwable)
                        onFailure()
                    },
                )
                .build()
            activeRequest = imageLoader.enqueue(request)
        }

        fun startSpecial(onFailure: () -> Unit) {
            val loadUri = resolveFallbackUri(uri)
            val dynamicFormat = detectFormat(loadUri, uri)
            val candidates = specialFormatsFor(dynamicFormat)
            if (candidates.isEmpty()) {
                onFailure()
                return
            }
            loadWithSpecialDrawables(
                uri = loadUri,
                candidates = candidates,
                onSuccess = { finishSuccess() },
                onFailure = { onFailure() },
            )
        }

        fun startJxl(onFailure: () -> Unit) {
            val loadUri = resolveFallbackUri(uri)
            loadWithJxlDrawable(
                uri = loadUri,
                sourceUri = uri,
                onSuccess = { finishSuccess() },
                onFailure = { onFailure() },
            )
        }

        fun startGlidePicasso(onFailure: () -> Unit) {
            val loadUri = resolveFallbackUri(uri)
            loadWithGlideThenPicasso(
                uri = loadUri,
                sourceUri = uri,
                onSuccess = { finishSuccess() },
                onFailure = { onFailure() },
            )
        }

        when (loadPlan) {
            LoadPlan.SPECIAL_FIRST -> {
                startSpecial {
                    if (!cont.isActive) return@startSpecial
                    startCoil {
                        if (!cont.isActive) return@startCoil
                        startGlidePicasso { finishFailure() }
                    }
                }
            }

            LoadPlan.JXL_FIRST -> {
                startJxl {
                    if (!cont.isActive) return@startJxl
                    startCoil {
                        if (!cont.isActive) return@startCoil
                        startGlidePicasso { finishFailure() }
                    }
                }
            }

            LoadPlan.GLIDE_FIRST -> {
                startGlidePicasso {
                    if (!cont.isActive) return@startGlidePicasso
                    startCoil { finishFailure() }
                }
            }

            LoadPlan.COIL_FIRST -> {
                startCoil {
                    if (!cont.isActive) return@startCoil
                    startSpecial {
                        if (!cont.isActive) return@startSpecial
                        startGlidePicasso { finishFailure() }
                    }
                }
            }
        }

        cont.invokeOnCancellation {
            activeRequest?.dispose()
            activeRequest = null
            activeSpecialDecodeJob?.cancel()
            activeSpecialDecodeJob = null
            Glide.with(this).clear(hiddenImage)
            Picasso.get().cancelRequest(hiddenImage)
        }
    }

    private enum class SpecialFormat {
        APNG,
        AVIF,
        WEBP,
    }

    private enum class LoadPlan {
        COIL_FIRST,
        SPECIAL_FIRST,
        JXL_FIRST,
        GLIDE_FIRST,
    }

    private fun resolveFallbackUri(uri: Uri): Uri {
        if (uri.scheme != "ente") return uri
        val cached = resolveEnteCacheFile(uri) ?: return uri
        if (!cached.exists() || cached.length() <= 0L) return uri
        return Uri.fromFile(cached)
    }

    private fun resolveEnteCacheFile(uri: Uri): File? {
        val accessToken = uri.host.orEmpty()
        val segments = uri.pathSegments
        if (accessToken.isBlank() || segments.size < 2) return null

        val kind = segments[0]
        val fileId = segments[1].toLongOrNull() ?: return null
        val cache = EnteImageCache(context.applicationContext)
        return when (kind) {
            "image" -> cache.imageFile(accessToken, fileId)
            "thumb" -> cache.previewFile(accessToken, fileId)
            else -> null
        }
    }

    private fun detectFormat(targetUri: Uri, sourceUri: Uri): ImageFormatClassifier.Result {
        val targetBytes = headBytesFromUri(targetUri)
        val sourceBytes = if (sourceUri != targetUri) headBytesFromUri(sourceUri) else null

        val targetResult = ImageFormatClassifier.classify(
            uri = targetUri,
            headerBytes = targetBytes,
        )
        if (targetResult.family != ImageFormatClassifier.Family.UNKNOWN_IMAGE &&
            targetResult.family != ImageFormatClassifier.Family.NON_IMAGE
        ) {
            return targetResult
        }

        return ImageFormatClassifier.classify(
            uri = sourceUri,
            headerBytes = sourceBytes,
        )
    }

    private fun loadPlanFor(result: ImageFormatClassifier.Result): LoadPlan {
        return when {
            result.family == ImageFormatClassifier.Family.JXL -> LoadPlan.JXL_FIRST
            result.isRaw -> LoadPlan.GLIDE_FIRST
            result.family == ImageFormatClassifier.Family.APNG ||
                result.family == ImageFormatClassifier.Family.AVIF ||
                result.family == ImageFormatClassifier.Family.WEBP_ANIMATED -> LoadPlan.SPECIAL_FIRST
            else -> LoadPlan.COIL_FIRST
        }
    }

    private fun loadWithSpecialDrawables(
        uri: Uri,
        candidates: List<SpecialFormat>,
        onSuccess: () -> Unit,
        onFailure: () -> Unit,
    ) {
        if (candidates.isEmpty()) {
            onFailure()
            return
        }

        activeSpecialDecodeJob?.cancel()
        activeSpecialDecodeJob = scope.launch {
            val drawable = try {
                withTimeout(8_000L) {
                    withContext(Dispatchers.IO) {
                        loadSpecialDrawable(uri, candidates)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                AppLog.error("Slideshow", "Special decoder timed out for ${uri.redactedForLog()}", e)
                null
            }

            if (!isAttachedToWindow) return@launch
            if (drawable != null) {
                hiddenImage.setImageDrawable(drawable)
                (drawable as? Animatable)?.start()
                onSuccess()
            } else {
                onFailure()
            }
        }
    }

    private fun specialFormatsFor(result: ImageFormatClassifier.Result): List<SpecialFormat> {
        return when (result.family) {
            ImageFormatClassifier.Family.APNG -> listOf(SpecialFormat.APNG)
            ImageFormatClassifier.Family.AVIF -> listOf(SpecialFormat.AVIF)
            ImageFormatClassifier.Family.WEBP_ANIMATED -> listOf(SpecialFormat.WEBP)
            else -> emptyList()
        }
    }

    private fun headBytesFromUri(uri: Uri): ByteArray? {
        return when (uri.scheme) {
            "file" -> {
                val path = uri.path.orEmpty()
                if (path.startsWith("/android_asset/")) {
                    val assetPath = path.removePrefix("/android_asset/")
                    runCatching {
                        context.assets.open(assetPath).use { input ->
                            val bytes = ByteArray(256 * 1024)
                            val read = input.read(bytes)
                            if (read <= 0) null else bytes.copyOf(read)
                        }
                    }.getOrNull()
                } else {
                    ImageFormatClassifier.readHead(File(path))
                }
            }

            "content" -> {
                runCatching {
                    context.contentResolver.openInputStream(uri)?.use { input ->
                        val bytes = ByteArray(256 * 1024)
                        val read = input.read(bytes)
                        if (read <= 0) null else bytes.copyOf(read)
                    }
                }.getOrNull()
            }

            else -> null
        }
    }

    private fun loadSpecialDrawable(uri: Uri, candidates: List<SpecialFormat>): Drawable? {
        return when (uri.scheme) {
            "file" -> {
                val path = uri.path.orEmpty()
                if (path.startsWith("/android_asset/")) {
                    val assetPath = path.removePrefix("/android_asset/")
                    tryCreateFromAsset(candidates, assetPath)
                } else {
                    val file = File(path)
                    if (!file.exists() || file.length() <= 0L) {
                        null
                    } else {
                        tryCreateFromFile(candidates, file)
                    }
                }
            }

            "content" -> {
                val copied = copyContentUriToCache(uri, ImageFormatClassifier.extensionFromUri(uri)) ?: return null
                tryCreateFromFile(candidates, copied)
            }

            else -> null
        }
    }

    private fun tryCreateFromFile(candidates: List<SpecialFormat>, file: File): Drawable? {
        candidates.forEach { format ->
            val drawable = runCatching {
                when (format) {
                    SpecialFormat.APNG -> APNGDrawable.fromFile(file.absolutePath)
                    SpecialFormat.AVIF -> AVIFDrawable.fromFile(file.absolutePath)
                    SpecialFormat.WEBP -> WebPDrawable.fromFile(file.absolutePath)
                }
            }.getOrNull()
            if (drawable != null) {
                return drawable
            }
        }
        return null
    }

    private fun tryCreateFromAsset(candidates: List<SpecialFormat>, assetPath: String): Drawable? {
        candidates.forEach { format ->
            val drawable = runCatching {
                when (format) {
                    SpecialFormat.APNG -> APNGDrawable.fromAsset(context, assetPath)
                    SpecialFormat.AVIF -> AVIFDrawable.fromAsset(context, assetPath)
                    SpecialFormat.WEBP -> WebPDrawable.fromAsset(context, assetPath)
                }
            }.getOrNull()
            if (drawable != null) {
                return drawable
            }
        }
        return null
    }

    private fun copyContentUriToCache(uri: Uri, ext: String?): File? {
        val dir = File(context.cacheDir, "special_decoders")
        if (!dir.exists()) {
            dir.mkdirs()
        }

        val suffix = ext?.takeIf { it.isNotBlank() } ?: "bin"
        val name = sha256Hex(uri.toString()).take(20)
        val outFile = File(dir, "$name.$suffix")

        return runCatching {
            context.contentResolver.openInputStream(uri)?.use { input ->
                outFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            } ?: throw IOException("Unable to open $uri")
            outFile
        }.getOrNull()
    }

    private fun loadWithJxlDrawable(
        uri: Uri,
        sourceUri: Uri,
        onSuccess: () -> Unit,
        onFailure: () -> Unit,
    ) {
        activeSpecialDecodeJob?.cancel()
        activeSpecialDecodeJob = scope.launch {
            val drawable = try {
                withTimeout(10_000L) {
                    withContext(Dispatchers.IO) {
                        loadJxlDrawable(uri)
                    }
                }
            } catch (e: TimeoutCancellationException) {
                AppLog.error("Slideshow", "JXL decode timed out for ${sourceUri.redactedForLog()}", e)
                null
            }

            if (!isAttachedToWindow) return@launch
            if (drawable != null) {
                hiddenImage.setImageDrawable(drawable)
                (drawable as? Animatable)?.start()
                onSuccess()
            } else {
                AppLog.error("Slideshow", "JXL decode failed for ${sourceUri.redactedForLog()}")
                onFailure()
            }
        }
    }

    private fun loadJxlDrawable(uri: Uri): Drawable? {
        val bytes = readAllBytes(uri) ?: return null

        val animatedDrawable = runCatching {
            JxlAnimatedImage(bytes).animatedDrawable
        }.getOrNull()
        if (animatedDrawable != null) {
            return animatedDrawable
        }

        val bitmap: Bitmap = runCatching {
            JxlCoder.decode(
                bytes,
                PreferredColorConfig.DEFAULT,
                ScaleMode.FIT,
                JxlToneMapper.REC2408,
            )
        }.getOrNull() ?: return null

        return BitmapDrawable(resources, bitmap)
    }

    private fun readAllBytes(uri: Uri): ByteArray? {
        return when (uri.scheme) {
            "file" -> {
                val path = uri.path.orEmpty()
                if (path.startsWith("/android_asset/")) {
                    val assetPath = path.removePrefix("/android_asset/")
                    runCatching { context.assets.open(assetPath).use { it.readBytes() } }.getOrNull()
                } else {
                    runCatching { File(path).takeIf { it.exists() && it.length() > 0L }?.readBytes() }.getOrNull()
                }
            }

            "content" -> runCatching {
                context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            }.getOrNull()

            else -> null
        }
    }

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return digest.joinToString("") { b -> "%02x".format(b) }
    }

    private fun loadWithGlideThenPicasso(
        uri: Uri,
        sourceUri: Uri,
        onSuccess: () -> Unit,
        onFailure: () -> Unit,
    ) {
        if (uri.scheme !in setOf("file", "content", "http", "https", "android.resource")) {
            AppLog.error("Slideshow", "Skipping Glide/Picasso for unsupported URI scheme: ${uri.scheme}")
            onFailure()
            return
        }

        Glide.with(this)
            .load(uri)
            .dontAnimate()
            .listener(
                object : RequestListener<Drawable> {
                    override fun onLoadFailed(
                        e: GlideException?,
                        model: Any?,
                        target: Target<Drawable>,
                        isFirstResource: Boolean,
                    ): Boolean {
                        AppLog.error("Slideshow", "Glide failed to load ${sourceUri.redactedForLog()}", e)

                        val picassoResult = runCatching {
                            Picasso.get()
                                .load(uri)
                                .config(Bitmap.Config.ARGB_8888)
                                .into(
                                    hiddenImage,
                                    object : Callback {
                                        override fun onSuccess() {
                                            onSuccess()
                                        }

                                        override fun onError(e: Exception?) {
                                            AppLog.error("Slideshow", "Picasso failed to load ${sourceUri.redactedForLog()}", e)
                                            onFailure()
                                        }
                                    },
                                )
                        }

                        if (picassoResult.isFailure) {
                            AppLog.error(
                                "Slideshow",
                                "Picasso threw before enqueue for ${sourceUri.redactedForLog()}",
                                picassoResult.exceptionOrNull(),
                            )
                            onFailure()
                        }

                        return true
                    }

                    override fun onResourceReady(
                        resource: Drawable,
                        model: Any,
                        target: Target<Drawable>?,
                        dataSource: GlideDataSource,
                        isFirstResource: Boolean,
                    ): Boolean {
                        hiddenImage.setImageDrawable(resource)
                        onSuccess()
                        return true
                    }
                },
            )
            .into(hiddenImage)
    }

    override fun onDetachedFromWindow() {
        clear()
        scope.cancel()
        super.onDetachedFromWindow()
    }
}
