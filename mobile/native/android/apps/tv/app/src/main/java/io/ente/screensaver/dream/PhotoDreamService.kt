package io.ente.photos.screensaver.dream

import android.service.dreams.DreamService
import android.view.LayoutInflater
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.imageloading.AppImageLoader
import io.ente.photos.screensaver.databinding.DreamLayoutBinding
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.permissions.MediaPermissions
import io.ente.photos.screensaver.prefs.PhotoSourceType
import io.ente.photos.screensaver.prefs.PreferencesRepository
import io.ente.photos.screensaver.slideshow.SlideshowController
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class PhotoDreamService : DreamService() {

    private var binding: DreamLayoutBinding? = null
    private var scope: CoroutineScope? = null

    private var preferencesRepository: PreferencesRepository? = null
    private var slideshowController: SlideshowController? = null

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()

        isFullscreen = true
        isInteractive = false
        isScreenBright = true

        AppLog.initialize(this)

        val localScope = MainScope()
        scope = localScope

        preferencesRepository = PreferencesRepository(this)

        val inflater = LayoutInflater.from(this)
        val localBinding = DreamLayoutBinding.inflate(inflater)
        binding = localBinding
        setContentView(localBinding.root)

        slideshowController = SlideshowController(
            context = this,
            scope = localScope,
            slideshowView = localBinding.slideshow,
            imageLoader = AppImageLoader.get(this),
            preferencesRepository = preferencesRepository!!,
        )
    }

    override fun onDreamingStarted() {
        super.onDreamingStarted()

        val localScope = scope ?: return
        val localBinding = binding ?: return
        val localPrefs = preferencesRepository ?: return
        val localController = slideshowController ?: return

        localScope.launch {
            val settings = localPrefs.get()
            val needsPermission = settings.sourceType == PhotoSourceType.MEDIASTORE
            if (needsPermission && !MediaPermissions.hasReadImagesPermission(this@PhotoDreamService)) {
                localBinding.slideshow.showMessage(getString(R.string.missing_permission))
            } else {
                localBinding.slideshow.showMessage(null)
            }
            localController.start()
        }
    }

    override fun onDreamingStopped() {
        slideshowController?.stop()
        super.onDreamingStopped()
    }

    override fun onDetachedFromWindow() {
        slideshowController?.stop()
        slideshowController = null
        preferencesRepository = null

        binding = null

        scope?.cancel()
        scope = null

        super.onDetachedFromWindow()
    }
}
