package io.ente.ensu

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.viewmodel.compose.viewModel
import io.ente.ensu.designsystem.EnsuTheme
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.utils.ApplySystemBars

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            EnsuTheme {
                ApplySystemBars(backgroundColor = EnsuColor.backgroundBase())
                val appViewModel: AppViewModel = viewModel()
                EnsuApp(appViewModel = appViewModel)
            }
        }
    }
}
