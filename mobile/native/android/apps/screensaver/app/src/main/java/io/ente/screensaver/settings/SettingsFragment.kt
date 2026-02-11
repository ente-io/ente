package io.ente.screensaver.settings

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import io.ente.screensaver.R
import io.ente.screensaver.prefs.SsaverPreferenceDataStore
import io.ente.screensaver.setup.SetupActivity
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel

class SettingsFragment : PreferenceFragmentCompat() {

    private val scope = MainScope()
    private var dataStore: SsaverPreferenceDataStore? = null

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        val store = SsaverPreferenceDataStore(requireContext().applicationContext)
        dataStore = store
        preferenceManager.preferenceDataStore = store

        setPreferencesFromResource(R.xml.preferences, rootKey)

        findPreference<Preference>("pref_change_album")?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), SetupActivity::class.java))
            true
        }

        findPreference<Preference>("pref_open_preview")?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), io.ente.screensaver.preview.PreviewActivity::class.java))
            true
        }

        findPreference<Preference>("pref_open_dream_settings")?.setOnPreferenceClickListener {
            openDreamSettings()
            true
        }

        findPreference<Preference>("pref_open_advanced")?.setOnPreferenceClickListener {
            startActivity(Intent(requireContext(), AdvancedSettingsActivity::class.java))
            true
        }
    }

    private fun openDreamSettings() {
        val context = requireContext()
        val attempts = listOf(
            Intent(Settings.ACTION_DREAM_SETTINGS),
            Intent().setClassName(
                "com.android.tv.settings",
                "com.android.tv.settings.device.display.daydream.DaydreamActivity",
            ),
            Intent().setClassName(
                "com.android.tv.settings",
                "com.android.tv.settings.display.daydream.DaydreamActivity",
            ),
            Intent(Intent.ACTION_MAIN).addCategory("android.intent.category.LEANBACK_SETTINGS"),
            Intent(Settings.ACTION_SETTINGS),
        )

        val launched = attempts.any { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            runCatching { startActivity(intent) }.isSuccess
        }

        if (!launched) {
            Toast.makeText(context, getString(R.string.unavailable_system_screensaver_settings), Toast.LENGTH_LONG).show()
        }
    }

    override fun onDestroy() {
        dataStore?.close()
        dataStore = null
        scope.cancel()
        super.onDestroy()
    }
}
