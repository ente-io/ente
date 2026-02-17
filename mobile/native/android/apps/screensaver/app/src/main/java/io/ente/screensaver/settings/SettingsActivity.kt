package io.ente.photos.screensaver.settings

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivitySettingsBinding
import io.ente.photos.screensaver.diagnostics.AdbInstructionsActivity
import io.ente.photos.screensaver.diagnostics.ScreensaverConfigurator
import io.ente.photos.screensaver.prefs.SsaverPreferenceDataStore
import io.ente.photos.screensaver.setup.SetupActivity

class SettingsActivity : AppCompatActivity() {

    private var binding: ActivitySettingsBinding? = null
    private var dataStore: SsaverPreferenceDataStore? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val viewBinding = ActivitySettingsBinding.inflate(layoutInflater)
        binding = viewBinding
        setContentView(viewBinding.root)

        dataStore = SsaverPreferenceDataStore(applicationContext)

        viewBinding.rowChangeAlbum.setOnClickListener {
            startActivity(Intent(this, SetupActivity::class.java))
        }

        viewBinding.rowSetScreensaver.setOnClickListener {
            when (val result = ScreensaverConfigurator.trySetAsScreensaver(this)) {
                is ScreensaverConfigurator.Result.Success -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                }

                is ScreensaverConfigurator.Result.NeedsWriteSecureSettings -> {
                    startActivity(Intent(this, AdbInstructionsActivity::class.java))
                }

                is ScreensaverConfigurator.Result.Error -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                }
            }
            updateSetScreensaverVisibility()
        }

        viewBinding.rowShuffle.setOnClickListener {
            toggleShuffle()
        }

        viewBinding.rowInterval.setOnClickListener {
            showIntervalDialog()
        }

        viewBinding.rowAdvanced.setOnClickListener {
            startActivity(Intent(this, AdvancedSettingsActivity::class.java))
        }

        viewBinding.rowChangeAlbum.post {
            viewBinding.rowChangeAlbum.requestFocus()
        }
    }

    override fun onResume() {
        super.onResume()
        updateSetScreensaverVisibility()
    }

    private fun toggleShuffle() {
        val store = dataStore ?: return
        val shuffleEnabled = store.getBoolean(KEY_PREF_SHUFFLE, true)
        val nextValue = !shuffleEnabled
        store.putBoolean(KEY_PREF_SHUFFLE, nextValue)

        val messageRes = if (nextValue) {
            R.string.settings_shuffle_enabled
        } else {
            R.string.settings_shuffle_disabled
        }
        Toast.makeText(this, getString(messageRes), Toast.LENGTH_SHORT).show()
    }

    private fun showIntervalDialog() {
        val store = dataStore ?: return

        val entries = resources.getStringArray(R.array.pref_interval_entries)
        val values = resources.getStringArray(R.array.pref_interval_values)
        if (entries.isEmpty() || values.isEmpty() || entries.size != values.size) return

        val currentValue = store.getString(KEY_PREF_INTERVAL_MS, DEFAULT_INTERVAL_MS)
        val selectedIndex = values.indexOf(currentValue).takeIf { it >= 0 } ?: 0

        AlertDialog.Builder(this)
            .setTitle(R.string.pref_title_slideshow_interval)
            .setSingleChoiceItems(entries, selectedIndex) { dialog, which ->
                store.putString(KEY_PREF_INTERVAL_MS, values[which])
                Toast.makeText(
                    this,
                    getString(R.string.settings_interval_updated, entries[which]),
                    Toast.LENGTH_SHORT,
                ).show()
                dialog.dismiss()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun updateSetScreensaverVisibility() {
        binding?.rowSetScreensaverContainer?.isVisible = !ScreensaverConfigurator.isScreensaverConfigured(this)
    }

    override fun onDestroy() {
        dataStore?.close()
        dataStore = null
        binding = null
        super.onDestroy()
    }

    companion object {
        private const val KEY_PREF_SHUFFLE = "pref_shuffle"
        private const val KEY_PREF_INTERVAL_MS = "pref_interval_ms"
        private const val DEFAULT_INTERVAL_MS = "60000"
    }
}
