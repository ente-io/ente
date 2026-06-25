import Foundation

#if canImport(UIKit)
import UIKit

func copyToPasteboard(_ value: String) {
    UIPasteboard.general.string = value
}
#elseif canImport(AppKit)
import AppKit

func copyToPasteboard(_ value: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(value, forType: .string)
}
#endif
