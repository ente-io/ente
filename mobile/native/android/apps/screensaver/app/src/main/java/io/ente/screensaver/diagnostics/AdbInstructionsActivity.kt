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

        binding.textCommands.text = formatGrantCommandForDisplay(ScreensaverConfigurator.adbCommands(this))
    }

    private fun formatGrantCommandForDisplay(command: String): String {
        val tail = "android.permission.WRITE_SECURE_SETTINGS"
        val splitIndex = command.indexOf(tail)
        if (splitIndex <= 0) return command

        val first = command.substring(0, splitIndex).trimEnd()
        val second = command.substring(splitIndex)
        return "$first \\\n$second"
    }
}
