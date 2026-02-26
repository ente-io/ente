package io.ente.ensu

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.data.auth.EnsuAuthService
import io.ente.ensu.data.logging.FileLogRepository
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.state.AppState
import io.ente.ensu.domain.store.AppStore
import kotlinx.coroutines.flow.Flow

@Composable
fun RootView(
    appState: AppState,
    store: AppStore,
    logs: List<LogEntry>,
    logRepository: FileLogRepository,
    authService: EnsuAuthService,
    currentEndpointFlow: Flow<String>
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(EnsuColor.backgroundBase())
    ) {
        HomeView(
            appState = appState,
            store = store,
            logs = logs,
            logRepository = logRepository,
            authService = authService,
            currentEndpointFlow = currentEndpointFlow
        )
    }
}
