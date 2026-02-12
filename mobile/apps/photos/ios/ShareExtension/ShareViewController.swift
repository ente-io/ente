#if canImport(receive_sharing_intent)
import receive_sharing_intent

class ShareViewController: RSIShareViewController {

    // Use this method to return false if you don't want to redirect to host app automatically.
    // Default is true
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
#elseif canImport(UIKit)
import UIKit

class ShareViewController: UIViewController {}
#else
import Foundation

class ShareViewController: NSObject {}
#endif
