package io.ente.photos.screensaver.settings

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivitySettingsBinding
import io.ente.photos.screensaver.diagnostics.AdbInstructionsActivity
import io.ente.photos.screensaver.diagnostics.ScreensaverConfigurator
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.prefs.SsaverPreferenceDataStore
import io.ente.photos.screensaver.setup.SetupActivity
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class SettingsActivity : AppCompatActivity() {

    private val scope = MainScope()
    private var binding: ActivitySettingsBinding? = null
    private var dataStore: SsaverPreferenceDataStore? = null
    private var settingsRows: List<View> = emptyList()
    private var rowTitleByContainer: Map<View, TextView> = emptyMap()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val viewBinding = ActivitySettingsBinding.inflate(layoutInflater)
        binding = viewBinding
        setContentView(viewBinding.root)

        dataStore = SsaverPreferenceDataStore(applicationContext)
        applyChangeAlbumValueMaxWidth()

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

        settingsRows = listOf(
            viewBinding.rowChangeAlbum,
            viewBinding.rowSetScreensaver,
            viewBinding.rowShuffle,
            viewBinding.rowInterval,
            viewBinding.rowAdvanced,
        )
        rowTitleByContainer = mapOf(
            viewBinding.rowChangeAlbum to viewBinding.rowChangeAlbumTitle,
            viewBinding.rowSetScreensaver to viewBinding.rowSetScreensaverTitle,
            viewBinding.rowShuffle to viewBinding.rowShuffleTitle,
            viewBinding.rowInterval to viewBinding.rowIntervalTitle,
            viewBinding.rowAdvanced to viewBinding.rowAdvancedTitle,
        )
        setupRowFocusStyling(settingsRows)

        viewBinding.rowChangeAlbum.post {
            viewBinding.rowChangeAlbum.requestFocus()
            refreshRowTextSizes()
        }
    }

    override fun onResume() {
        super.onResume()
        applyChangeAlbumValueMaxWidth()
        updateSetScreensaverVisibility()
        updateAlbumValue()
        updateShuffleValue()
        updateIntervalValue()
    }

    private fun toggleShuffle() {
        val store = dataStore ?: return
        val shuffleEnabled = store.getBoolean(KEY_PREF_SHUFFLE, true)
        val nextValue = !shuffleEnabled
        store.putBoolean(KEY_PREF_SHUFFLE, nextValue)
        setShuffleValue(nextValue)

        val messageRes = if (nextValue) {
            R.string.settings_shuffle_enabled
        } else {
            R.string.settings_shuffle_disabled
        }
        Toast.makeText(this, getString(messageRes), Toast.LENGTH_SHORT).show()
    }

    private fun updateShuffleValue() {
        val store = dataStore ?: return
        val shuffleEnabled = store.getBoolean(KEY_PREF_SHUFFLE, true)
        setShuffleValue(shuffleEnabled)
    }

    private fun setShuffleValue(enabled: Boolean) {
        val viewBinding = binding ?: return
        viewBinding.rowShuffleValue.text = getString(
            if (enabled) R.string.settings_toggle_on else R.string.settings_toggle_off,
        )
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
                setIntervalValue(entries[which])
                dialog.dismiss()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun updateIntervalValue() {
        val store = dataStore ?: return

        val entries = resources.getStringArray(R.array.pref_interval_entries)
        val values = resources.getStringArray(R.array.pref_interval_values)
        if (entries.isEmpty() || values.isEmpty() || entries.size != values.size) return

        val currentValue = store.getString(KEY_PREF_INTERVAL_MS, DEFAULT_INTERVAL_MS)
        val index = values.indexOf(currentValue).takeIf { it >= 0 } ?: 0
        setIntervalValue(entries[index])
    }

    private fun setIntervalValue(value: String) {
        val viewBinding = binding ?: return
        viewBinding.rowIntervalValue.text = value
    }

    private fun updateAlbumValue() {
        val viewBinding = binding ?: return
        scope.launch {
            val repo = EntePublicAlbumRepository.get(this@SettingsActivity)
            val title = repo.getAlbumName(refreshIfMissing = true)
                ?: repo.getConfig()?.publicUrl?.let { albumLabelFromUrl(it) }

            viewBinding.rowChangeAlbumValue.text =
                title?.takeIf { it.isNotBlank() } ?: getString(R.string.settings_album_not_set)
        }
    }

    private fun applyChangeAlbumValueMaxWidth() {
        val viewBinding = binding ?: return
        viewBinding.rowChangeAlbum.post {
            val rowWidth = viewBinding.rowChangeAlbum.width
                .takeIf { it > 0 }
                ?: resources.displayMetrics.widthPixels
            viewBinding.rowChangeAlbumValue.maxWidth = (rowWidth * 0.5f).toInt()
        }
    }

    private fun setupRowFocusStyling(rows: List<View>) {
        rows.forEach { row ->
            val titleView = rowTitleByContainer[row] ?: return@forEach
            titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, ROW_TEXT_SIZE_NORMAL_SP)
            row.setOnFocusChangeListener { _, hasFocus ->
                val textSize = if (hasFocus) {
                    ROW_TEXT_SIZE_FOCUSED_SP
                } else {
                    ROW_TEXT_SIZE_NORMAL_SP
                }
                titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, textSize)
            }
        }
    }

    private fun refreshRowTextSizes() {
        settingsRows.forEach { row ->
            val titleView = rowTitleByContainer[row] ?: return@forEach
            val textSize = if (row.hasFocus()) {
                ROW_TEXT_SIZE_FOCUSED_SP
            } else {
                ROW_TEXT_SIZE_NORMAL_SP
            }
            titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, textSize)
        }
    }

    private fun updateSetScreensaverVisibility() {
        val viewBinding = binding ?: return
        val shouldShowSetScreensaver = !ScreensaverConfigurator.isScreensaverConfigured(this)
        viewBinding.rowSetScreensaverContainer.isVisible = shouldShowSetScreensaver

        if (!shouldShowSetScreensaver && viewBinding.rowSetScreensaver.hasFocus()) {
            viewBinding.rowChangeAlbum.requestFocus()
        }

        refreshRowTextSizes()
    }

    private fun albumLabelFromUrl(publicUrl: String): String? {
        val uri = runCatching { Uri.parse(publicUrl) }.getOrNull() ?: return null

        val queryName = listOf("name", "title", "album")
            .firstNotNullOfOrNull { key -> uri.getQueryParameter(key)?.trim()?.takeIf { it.isNotBlank() } }
        if (!queryName.isNullOrBlank()) return queryName

        val token = uri.getQueryParameter("t")?.trim().orEmpty()
        val pathLabel = uri.pathSegments
            .asReversed()
            .firstOrNull { segment ->
                val clean = segment.trim()
                clean.isNotBlank() && clean != token && clean.lowercase() !in setOf("a", "album", "albums", "share")
            }
            ?.replace('-', ' ')
            ?.replace('_', ' ')
            ?.trim()
            ?.takeIf { it.isNotBlank() }

        return pathLabel
    }

    override fun onDestroy() {
        dataStore?.close()
        dataStore = null
        settingsRows = emptyList()
        rowTitleByContainer = emptyMap()
        binding = null
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val KEY_PREF_SHUFFLE = "pref_shuffle"
        private const val KEY_PREF_INTERVAL_MS = "pref_interval_ms"
        private const val DEFAULT_INTERVAL_MS = "60000"

        private const val ROW_TEXT_SIZE_NORMAL_SP = 32f
        private const val ROW_TEXT_SIZE_FOCUSED_SP = 36f
    }
}
