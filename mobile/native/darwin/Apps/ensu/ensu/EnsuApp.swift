import SwiftUI

@main
struct EnsuApp: App {
    @StateObject private var appState = EnsuAppState()
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url)
                }
        }
    }
}
