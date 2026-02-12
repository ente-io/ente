package io.ente.photos.screensaver.settings

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.diagnostics.AdbInstructionsActivity
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

        findPreference<Preference>("pref_adb_instructions")?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), AdbInstructionsActivity::class.java))
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

        findPreference<ListPreference>("pref_source")?.summaryProvider =
            ListPreference.SimpleSummaryProvider.getInstance()
        findPreference<ListPreference>("pref_interval_ms")?.summaryProvider =
            ListPreference.SimpleSummaryProvider.getInstance()
        findPreference<ListPreference>("pref_ente_cache_limit")?.summaryProvider =
            ListPreference.SimpleSummaryProvider.getInstance()
        findPreference<ListPreference>("pref_ente_refresh_interval_ms")?.summaryProvider =
            ListPreference.SimpleSummaryProvider.getInstance()
        findPreference<ListPreference>("pref_fit_mode")?.summaryProvider =
            ListPreference.SimpleSummaryProvider.getInstance()
    }

    override fun onDestroy() {
        dataStore?.close()
        dataStore = null
        scope.cancel()
        super.onDestroy()
    }
}
