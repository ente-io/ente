import Foundation

enum ChatRecovery {
    private static let resetSignals = [
        "stream pull failed",
        "invalid blob",
        "invalid encrypted"
    ]

    static func shouldResetFromMessage(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return resetSignals.contains { lowercased.contains($0) }
    }
}
