import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    @Published var isVisible: Bool = false

    #if canImport(UIKit)
    private var showObserver: NSObjectProtocol?
    private var hideObserver: NSObjectProtocol?

    init() {
        showObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                height = frame.height
            }
            isVisible = height > 100
        }

        hideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.height = 0
            self?.isVisible = false
        }
    }

    deinit {
        if let showObserver { NotificationCenter.default.removeObserver(showObserver) }
        if let hideObserver { NotificationCenter.default.removeObserver(hideObserver) }
    }
    #else
    init() {}
    #endif
}

extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
