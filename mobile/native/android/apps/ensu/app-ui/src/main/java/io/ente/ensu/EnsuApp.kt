package io.ente.ensu

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue

@Composable
fun EnsuApp(appViewModel: AppViewModel) {
    val appState by appViewModel.store.state.collectAsState()
    val logs by appViewModel.logRepository.logs.collectAsState()
    RootView(
        appState = appState,
        store = appViewModel.store,
        logs = logs,
        authService = appViewModel.authService,
        currentEndpointFlow = appViewModel.currentEndpointFlow
    )
}
