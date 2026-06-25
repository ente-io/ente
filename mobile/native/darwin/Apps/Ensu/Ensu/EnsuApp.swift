import SwiftUI

@main
struct EnsuApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(EnsuAppDelegate.self) private var appDelegate
    #endif

    init() {
        EnsuLogging.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
