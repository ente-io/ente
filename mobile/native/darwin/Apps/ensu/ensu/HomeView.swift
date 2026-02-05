#if canImport(EnteCore)
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: EnsuAppState
    @StateObject private var chatModel = ChatViewModel()
    @State private var isShowingAuth = false
    @State private var didTriggerInitialSync = false

    var body: some View {
        ChatView(viewModel: chatModel, isShowingAuth: $isShowingAuth)
            .platformFullScreenCover(isPresented: $isShowingAuth) {
                AuthFlowView()
            }
            .task {
                guard appState.isLoggedIn, !didTriggerInitialSync else { return }
                didTriggerInitialSync = true
                chatModel.syncAfterLogin()
            }
            .onChange(of: appState.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    isShowingAuth = false
                    didTriggerInitialSync = true
                    chatModel.syncAfterLogin()
                } else {
                    didTriggerInitialSync = false
                    chatModel.handleLogout()
                }
            }
    }
}
#else
import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("Home unavailable")
    }
}
#endif
