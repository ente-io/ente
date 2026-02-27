#if canImport(receive_sharing_intent)
import receive_sharing_intent
#endif

class ShareViewController: RSIShareViewController {

    // Use this method to return false if you don't want to redirect to host app automatically.
    // Default is true
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
