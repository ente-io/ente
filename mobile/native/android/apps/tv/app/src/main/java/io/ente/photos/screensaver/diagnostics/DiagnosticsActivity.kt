package io.ente.photos.screensaver.diagnostics

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivityDiagnosticsBinding

class DiagnosticsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityDiagnosticsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppLog.initialize(this)
        binding = ActivityDiagnosticsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.textLogs.text = dumpLogs()
    }

    private fun dumpLogs(): String {
        return AppLog.dump(getString(R.string.diagnostics_no_recent_logs))
    }
}
