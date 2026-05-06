#if os(iOS)
import UIKit

final class EnsuAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        ModelDownloadManager.shared.setBackgroundCompletionHandler(completionHandler)
    }
}
#endif
