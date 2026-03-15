@file:Suppress("PackageDirectoryMismatch")

package io.ente.photos.screensaver.settings

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.diagnostics.AdbInstructionsActivity
import io.ente.photos.screensaver.diagnostics.ScreensaverConfigurator
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.prefs.SsaverPreferenceDataStore
import io.ente.photos.screensaver.setup.SetupActivity
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class SettingsFragment : PreferenceFragmentCompat() {

    private val scope = MainScope()
    private var dataStore: SsaverPreferenceDataStore? = null
    private var changeAlbumPreference: Preference? = null
    private var setScreensaverPreference: Preference? = null

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        val store = SsaverPreferenceDataStore(requireContext().applicationContext)
        dataStore = store
        preferenceManager.preferenceDataStore = store

        setPreferencesFromResource(R.xml.preferences, rootKey)

        changeAlbumPreference = findPreference("pref_change_album")
        changeAlbumPreference?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), SetupActivity::class.java))
            true
        }

        setScreensaverPreference = findPreference("pref_set_screensaver")
        setScreensaverPreference?.setOnPreferenceClickListener {
            when (val result = ScreensaverConfigurator.trySetAsScreensaver(requireContext())) {
                is ScreensaverConfigurator.Result.Success -> {
                    Toast.makeText(requireContext(), result.message, Toast.LENGTH_LONG).show()
                }

                is ScreensaverConfigurator.Result.NeedsWriteSecureSettings -> {
                    startActivity(Intent(requireContext(), AdbInstructionsActivity::class.java))
                }

                is ScreensaverConfigurator.Result.Error -> {
                    Toast.makeText(requireContext(), result.message, Toast.LENGTH_LONG).show()
                }
            }
            updateSetScreensaverVisibility()
            true
        }

        findPreference<Preference>("pref_open_advanced")?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), AdvancedSettingsActivity::class.java))
            true
        }

        findPreference<ListPreference>("pref_interval_ms")?.summaryProvider =
            ListPreference.SimpleSummaryProvider.getInstance()

        updateSetScreensaverVisibility()
        updateAlbumSummary()
    }

    override fun onResume() {
        super.onResume()
        updateSetScreensaverVisibility()
        updateAlbumSummary()
    }

    private fun updateSetScreensaverVisibility() {
        val context = context ?: return
        setScreensaverPreference?.isVisible = !ScreensaverConfigurator.isScreensaverConfigured(context)
    }

    private fun updateAlbumSummary() {
        val context = context ?: return
        scope.launch {
            val config = EntePublicAlbumRepository.get(context).getConfig()
            val summary = if (config == null) {
                getString(R.string.pref_change_album_summary)
            } else {
                config.albumName?.takeIf { it.isNotBlank() }
                    ?: albumLabelFromUrl(config.publicUrl)
            }
            changeAlbumPreference?.summary = summary
        }
    }

    private fun albumLabelFromUrl(publicUrl: String): String {
        val uri = runCatching { Uri.parse(publicUrl) }.getOrNull() ?: return publicUrl

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

        return pathLabel ?: (uri.host?.removePrefix("www.") ?: publicUrl)
    }

    override fun onDestroy() {
        dataStore?.close()
        dataStore = null
        scope.cancel()
        super.onDestroy()
    }
}
