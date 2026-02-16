package io.ente.photos.screensaver.main

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import io.ente.photos.screensaver.BuildConfig
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivityMainPreviewBinding
import io.ente.photos.screensaver.diagnostics.AdbInstructionsActivity
import io.ente.photos.screensaver.diagnostics.AppLog
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.imageloading.AppImageLoader
import io.ente.photos.screensaver.permissions.MediaPermissions
import io.ente.photos.screensaver.prefs.PhotoSourceType
import io.ente.photos.screensaver.prefs.PreferencesRepository
import io.ente.photos.screensaver.settings.SettingsActivity
import io.ente.photos.screensaver.setup.SetupActivity
import io.ente.photos.screensaver.slideshow.SlideshowController
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

class MainActivity : AppCompatActivity() {

    private var previewBinding: ActivityMainPreviewBinding? = null

    private val scope = MainScope()
    private val handler = Handler(Looper.getMainLooper())

    // Preview mode dependencies
    private var preferencesRepository: PreferencesRepository? = null
    private var slideshowController: SlideshowController? = null
    private var hideHintRunnable: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppLog.initialize(this)

        if (BuildConfig.DEBUG) {
            startActivity(Intent(this, AdbInstructionsActivity::class.java))
            finish()
            return
        }

        // Check if album is configured
        val repo = EntePublicAlbumRepository.get(this)
        val isConfigured = runBlocking { repo.getConfig() != null }

        if (isConfigured) {
            showPreviewMode()
        } else {
            startActivity(
                Intent(this, SetupActivity::class.java)
                    .putExtra(SetupActivity.EXTRA_AUTO_RETURN_TO_PREVIEW, true),
            )
            finish()
        }
    }

    private fun showPreviewMode() {
        previewBinding = ActivityMainPreviewBinding.inflate(layoutInflater)
        setContentView(previewBinding!!.root)

        // Initialize preview dependencies
        preferencesRepository = PreferencesRepository(this)
        slideshowController = SlideshowController(
            context = this,
            scope = scope,
            slideshowView = previewBinding!!.slideshow,
            imageLoader = AppImageLoader.get(this),
            preferencesRepository = preferencesRepository!!,
        )

        // Show hint and auto-hide after 6 seconds
        previewBinding!!.hintSettings.visibility = View.VISIBLE
        hideHintRunnable = Runnable {
            previewBinding?.hintSettings?.animate()
                ?.alpha(0f)
                ?.setDuration(300)
                ?.withEndAction {
                    previewBinding?.hintSettings?.visibility = View.GONE
                    previewBinding?.hintSettings?.alpha = 1f
                }
        }
        handler.postDelayed(hideHintRunnable!!, 6000)
    }

    override fun onStart() {
        super.onStart()

        if (previewBinding != null) {
            // Preview mode: start slideshow
            scope.launch {
                val settings = preferencesRepository?.get()
                if (settings != null) {
                    val needsPermission = settings.sourceType == PhotoSourceType.MEDIASTORE
                    val hasPermission = MediaPermissions.hasReadImagesPermission(this@MainActivity)
                    if (needsPermission && !hasPermission) {
                        previewBinding?.slideshow?.showMessage(getString(R.string.missing_permission))
                    } else {
                        previewBinding?.slideshow?.showMessage(null)
                    }
                    slideshowController?.start()
                }
            }
        }
    }

    override fun onStop() {
        slideshowController?.stop()
        super.onStop()
    }

    override fun onDestroy() {
        hideHintRunnable?.let { handler.removeCallbacks(it) }
        hideHintRunnable = null

        slideshowController?.stop()
        slideshowController = null
        preferencesRepository = null

        previewBinding = null

        scope.cancel()
        super.onDestroy()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_MENU -> {
                openSettings()
                true
            }

            else -> super.onKeyDown(keyCode, event)
        }
    }

    private fun openSettings() {
        startActivity(Intent(this, SettingsActivity::class.java))
    }
}
