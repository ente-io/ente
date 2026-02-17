@file:Suppress("PackageDirectoryMismatch")

package io.ente.photos.screensaver.settings

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.diagnostics.DiagnosticsActivity
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import io.ente.photos.screensaver.prefs.SsaverPreferenceDataStore
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class AdvancedSettingsFragment : PreferenceFragmentCompat() {

    private val scope = MainScope()
    private var dataStore: SsaverPreferenceDataStore? = null

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        val store = SsaverPreferenceDataStore(requireContext().applicationContext)
        dataStore = store
        preferenceManager.preferenceDataStore = store

        setPreferencesFromResource(R.xml.advanced_preferences, rootKey)

        findPreference<Preference>("pref_diagnostics")?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), DiagnosticsActivity::class.java))
            true
        }

        findPreference<Preference>("pref_clear_cache")?.setOnPreferenceClickListener {
            scope.launch {
                val repo = EntePublicAlbumRepository.get(requireContext())
                val config = repo.getConfig()
                if (config == null) {
                    Toast.makeText(requireContext(), getString(R.string.ente_cache_clear_none), Toast.LENGTH_LONG).show()
                } else {
                    repo.clearCache()
                    Toast.makeText(requireContext(), getString(R.string.ente_cache_cleared), Toast.LENGTH_LONG).show()
                }
            }
            true
        }

    }

    override fun onDestroy() {
        dataStore?.close()
        dataStore = null
        scope.cancel()
        super.onDestroy()
    }
}
