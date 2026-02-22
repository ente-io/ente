package io.ente.photos.screensaver.preview

import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.imageloading.AppImageLoader
import io.ente.photos.screensaver.databinding.ActivityPreviewBinding
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.permissions.MediaPermissions
import io.ente.photos.screensaver.power.ScreenWakeLockManager
import io.ente.photos.screensaver.prefs.PhotoSourceType
import io.ente.photos.screensaver.prefs.PreferencesRepository
import io.ente.photos.screensaver.slideshow.SlideshowController
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class PreviewActivity : AppCompatActivity() {

    private lateinit var binding: ActivityPreviewBinding
    private val scope = MainScope()

    private lateinit var preferencesRepository: PreferencesRepository
    private lateinit var slideshowController: SlideshowController
    private lateinit var wakeLockManager: ScreenWakeLockManager

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        if (!granted) {
            binding.slideshow.showMessage(getString(R.string.missing_permission))
        }
        slideshowController.start()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppLog.initialize(this)
        binding = ActivityPreviewBinding.inflate(layoutInflater)
        setContentView(binding.root)

        preferencesRepository = PreferencesRepository(this)
        slideshowController = SlideshowController(
            context = this,
            scope = scope,
            slideshowView = binding.slideshow,
            imageLoader = AppImageLoader.get(this),
            preferencesRepository = preferencesRepository,
        )
        wakeLockManager = ScreenWakeLockManager(this)
    }

    override fun onStart() {
        super.onStart()
        wakeLockManager.acquire()

        scope.launch {
            val settings = preferencesRepository.get()
            val needsPermission = settings.sourceType == PhotoSourceType.MEDIASTORE
            val hasPermission = MediaPermissions.hasReadImagesPermission(this@PreviewActivity)
            if (needsPermission && !hasPermission) {
                binding.slideshow.showMessage(getString(R.string.missing_permission))
                val permission = MediaPermissions.requiredReadImagesPermission()
                if (permission != null) {
                    permissionLauncher.launch(permission)
                } else {
                    slideshowController.start()
                }
            } else {
                binding.slideshow.showMessage(null)
                slideshowController.start()
            }
        }
    }

    override fun onStop() {
        wakeLockManager.release()
        slideshowController.stop()
        super.onStop()
    }

    override fun onDestroy() {
        wakeLockManager.release()
        super.onDestroy()
        scope.cancel()
    }
}
