#if canImport(EnteCore)
import Foundation

struct WhatsNewEntry: Equatable {
    let title: String
    let description: String
}

enum WhatsNewContent {
    static let version = 1
    static let entries: [WhatsNewEntry] = [
        WhatsNewEntry(
            title: "In-app release notes",
            description: "Ensu can now show a short What's new note after updates, with platform-specific entries and a changelog version independent from the app build version."
        )
    ]
}
#endif
