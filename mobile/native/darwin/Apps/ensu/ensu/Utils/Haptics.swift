import Foundation

#if canImport(UIKit)
import UIKit

func hapticTap() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

func hapticMedium() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}

func hapticHeavy() {
    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
}

func hapticSuccess() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}

func hapticWarning() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
}

func hapticError() {
    UINotificationFeedbackGenerator().notificationOccurred(.error)
}

#elseif canImport(AppKit)
import AppKit

func hapticTap() {
    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
}

func hapticMedium() {
    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
}

func hapticHeavy() {
    NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
}

func hapticSuccess() {
    hapticTap()
}

func hapticWarning() {
    hapticMedium()
}

func hapticError() {
    hapticHeavy()
}
#endif
