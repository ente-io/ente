import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: EnsuAppState
    @StateObject private var chatModel = ChatViewModel()
    @State private var isShowingAuth = false

    var body: some View {
        ChatView(viewModel: chatModel, isShowingAuth: $isShowingAuth)
            .platformFullScreenCover(isPresented: $isShowingAuth) {
                AuthFlowView()
            }
            .onChange(of: appState.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    isShowingAuth = false
                }
            }
    }
}
