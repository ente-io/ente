#if canImport(EnteCore)
import SwiftUI

struct HomeView: View {
    @StateObject private var chatModel = ChatViewModel()

    var body: some View {
        ChatView(viewModel: chatModel)
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
