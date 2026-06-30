package io.ente.ensu

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue

@Composable
fun App(appViewModel: AppViewModel) {
    val appState by appViewModel.store.state.collectAsState()
    RootView(
        appState = appState,
        store = appViewModel.store,
        logRepository = appViewModel.logRepository,
        advancedSettingsDataStore = appViewModel.advancedSettingsDataStore,
        appVersion = appViewModel.appVersion,
        configDefaults = appViewModel.configDefaults
    )
}
