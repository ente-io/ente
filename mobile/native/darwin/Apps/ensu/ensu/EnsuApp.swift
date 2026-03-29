import SwiftUI

@main
struct EnsuApp: App {
    @StateObject private var appState = EnsuAppState()
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    #if os(iOS)
    @UIApplicationDelegateAdaptor(EnsuAppDelegate.self) private var appDelegate
    #endif

    init() {
        EnsuLogging.shared.start()
    }

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
