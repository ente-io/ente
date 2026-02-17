import Foundation

@MainActor
final class DeepLinkRouter: ObservableObject {
    @Published var lastURL: URL?

    func handle(_ url: URL) {
        lastURL = url
    }
}
