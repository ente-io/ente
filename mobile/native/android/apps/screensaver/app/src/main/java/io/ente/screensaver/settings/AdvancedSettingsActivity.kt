package io.ente.photos.screensaver.settings

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivityAdvancedSettingsBinding
import io.ente.photos.screensaver.diagnostics.DiagnosticsActivity
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class AdvancedSettingsActivity : AppCompatActivity() {

    private val scope = MainScope()
    private var binding: ActivityAdvancedSettingsBinding? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val viewBinding = ActivityAdvancedSettingsBinding.inflate(layoutInflater)
        binding = viewBinding
        setContentView(viewBinding.root)

        viewBinding.rowDiagnostics.setOnClickListener {
            startActivity(Intent(this, DiagnosticsActivity::class.java))
        }

        viewBinding.rowClearCache.setOnClickListener {
            scope.launch {
                val repo = EntePublicAlbumRepository.get(this@AdvancedSettingsActivity)
                val config = repo.getConfig()
                if (config == null) {
                    Toast.makeText(
                        this@AdvancedSettingsActivity,
                        getString(R.string.ente_cache_clear_none),
                        Toast.LENGTH_LONG,
                    ).show()
                } else {
                    repo.clearCache()
                    Toast.makeText(
                        this@AdvancedSettingsActivity,
                        getString(R.string.ente_cache_cleared),
                        Toast.LENGTH_LONG,
                    ).show()
                }
            }
        }

        viewBinding.rowClearCache.post {
            viewBinding.rowClearCache.requestFocus()
        }
    }

    override fun onDestroy() {
        binding = null
        scope.cancel()
        super.onDestroy()
    }
}
