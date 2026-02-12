package io.ente.photos.screensaver.diagnostics

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import io.ente.photos.screensaver.databinding.ActivityAdbInstructionsBinding

class AdbInstructionsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAdbInstructionsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAdbInstructionsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.textCommands.text = ScreensaverConfigurator.adbCommands(this)
    }
}
