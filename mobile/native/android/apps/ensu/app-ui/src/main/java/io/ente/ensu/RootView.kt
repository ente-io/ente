package io.ente.ensu

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import io.ente.ensu.data.AdvancedSettingsDataStore
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.data.logging.FileLogRepository
import io.ente.ensu.domain.model.EnsuDefaults
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.store.AppStore

@Composable
fun RootView(
    appState: AppState,
    store: AppStore,
    logRepository: FileLogRepository,
    advancedSettingsDataStore: AdvancedSettingsDataStore,
    appVersion: String,
    ensuDefaults: EnsuDefaults
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(EnsuColor.backgroundBase())
    ) {
        HomeView(
            appState = appState,
            store = store,
            logRepository = logRepository,
            advancedSettingsDataStore = advancedSettingsDataStore,
            appVersion = appVersion,
            ensuDefaults = ensuDefaults
        )
    }
}
