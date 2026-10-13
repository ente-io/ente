import Foundation

/// Explicit stable IDs preserve a chat's choices when sources are added later.
struct ChatSourceSelection: Codable, Equatable, Sendable {
    var selectedPackIDs: Set<String> = []
    var selectedCollectionIDs: Set<String> = []

    func includesPack(_ id: String) -> Bool { selectedPackIDs.contains(id) }
    func includesCollection(_ id: String) -> Bool { selectedCollectionIDs.contains(id) }

    mutating func setPack(_ id: String, enabled: Bool) {
        if enabled { selectedPackIDs.insert(id) } else { selectedPackIDs.remove(id) }
    }

    mutating func setCollection(_ id: String, enabled: Bool) {
        if enabled { selectedCollectionIDs.insert(id) } else { selectedCollectionIDs.remove(id) }
    }
}

enum ChatSourceDestination: Equatable {
    case session(UUID)
    case draft(UUID)
}

/// Source choices are local because notes folders and downloaded packs belong to this device.
final class ChatSourceSelectionStore {
    private let defaults: UserDefaults
    private let prefix = "ensu.chat_sources."
    private var draftID = UUID()
    private var committedDrafts: [UUID: UUID] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func selection(for sessionID: UUID?) -> ChatSourceSelection? {
        guard let data = defaults.data(forKey: key(sessionID)),
            let selection = try? JSONDecoder().decode(ChatSourceSelection.self, from: data)
        else { return nil }
        return selection
    }

    func save(_ selection: ChatSourceSelection, for sessionID: UUID?) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        defaults.set(data, forKey: key(sessionID))
    }

    func initialize(
        for sessionID: UUID?, available: ChatSourceSelection, inventoryReady: Bool = true
    ) -> ChatSourceSelection? {
        if let saved = selection(for: sessionID) { return saved }
        guard inventoryReady else { return nil }
        save(available, for: sessionID)
        return available
    }

    func commitDraft(to sessionID: UUID) {
        if let draft = selection(for: nil) { save(draft, for: sessionID) }
        committedDrafts[draftID] = sessionID
        remove(nil)
    }

    func remove(_ sessionID: UUID?) {
        defaults.removeObject(forKey: key(sessionID))
        if sessionID == nil { draftID = UUID() }
    }

    func destination(for sessionID: UUID?) -> ChatSourceDestination {
        sessionID.map(ChatSourceDestination.session) ?? .draft(draftID)
    }

    /// An async add must follow its original draft into the chat created from it.
    func resolve(_ destination: ChatSourceDestination) -> ChatSourceDestination? {
        switch destination {
        case .session:
            return destination
        case .draft(let id):
            if let committed = committedDrafts[id] { return .session(committed) }
            return id == draftID ? destination : nil
        }
    }

    private func key(_ sessionID: UUID?) -> String {
        prefix + (sessionID?.uuidString.lowercased() ?? "draft")
    }
}
