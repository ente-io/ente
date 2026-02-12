package io.ente.photos.screensaver.settings

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import io.ente.photos.screensaver.R

class AdvancedSettingsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)

        if (savedInstanceState == null) {
            supportFragmentManager
                .beginTransaction()
                .replace(R.id.settings_container, AdvancedSettingsFragment())
                .commit()
        }
        
        // Set title for the activity
        title = getString(R.string.advanced_settings_title)
    }
}
