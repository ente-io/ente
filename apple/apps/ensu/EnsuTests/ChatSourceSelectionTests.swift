import XCTest
@testable import Ensu

final class ChatSourceSelectionTests: XCTestCase {
    private var suite: String!
    private var defaults: UserDefaults!
    private var store: ChatSourceSelectionStore!

    override func setUp() {
        super.setUp()
        suite = "ChatSourceSelectionTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        store = ChatSourceSelectionStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        store = nil
        defaults = nil
        super.tearDown()
    }

    func testNewChatStartsWithAllCurrentSourcesAndDoesNotPickUpLaterAdditions() {
        let chat = UUID()
        let original = ChatSourceSelection(
            selectedPackIDs: ["pack-a"], selectedCollectionIDs: ["notes-a"])
        XCTAssertEqual(store.initialize(for: chat, available: original), original)

        let expanded = ChatSourceSelection(
            selectedPackIDs: ["pack-a", "pack-b"], selectedCollectionIDs: ["notes-a", "notes-b"])
        XCTAssertEqual(store.initialize(for: chat, available: expanded), original)
        XCTAssertEqual(store.initialize(for: UUID(), available: expanded), expanded)
    }

    func testAllOffPersistsAcrossRelaunchAndIsIndependentOfOtherChats() throws {
        let chat = UUID()
        let other = UUID()
        store.save(ChatSourceSelection(), for: chat)
        let selected = ChatSourceSelection(
            selectedPackIDs: ["pack"], selectedCollectionIDs: ["folder"])
        store.save(selected, for: other)

        let restored = ChatSourceSelectionStore(defaults: defaults)
        XCTAssertEqual(restored.initialize(for: chat, available: selected), ChatSourceSelection())
        XCTAssertEqual(try XCTUnwrap(restored.selection(for: other)), selected)
    }

    func testFailedInventoryDoesNotPersistIncompleteDefaultsOrReplaceSavedChoices() {
        let chat = UUID()
        XCTAssertNil(
            store.initialize(for: chat, available: ChatSourceSelection(), inventoryReady: false))
        XCTAssertNil(store.selection(for: chat))

        let complete = ChatSourceSelection(
            selectedPackIDs: ["pack"], selectedCollectionIDs: ["folder"])
        XCTAssertEqual(store.initialize(for: chat, available: complete), complete)
        XCTAssertEqual(
            store.initialize(for: chat, available: ChatSourceSelection(), inventoryReady: false),
            complete)
    }

    func testDraftChoicesTransferAndAsyncAddFollowsDraftIntoCreatedChat() {
        let destination = store.destination(for: nil)
        let selected = ChatSourceSelection(selectedCollectionIDs: ["folder"])
        store.save(selected, for: nil)
        let chat = UUID()
        store.commitDraft(to: chat)

        XCTAssertEqual(store.selection(for: chat), selected)
        XCTAssertNil(store.selection(for: nil))
        XCTAssertEqual(store.resolve(destination), .session(chat))
        XCTAssertNotEqual(store.destination(for: nil), destination)
    }

    func testAsyncAddForDiscardedDraftDoesNotSelectSourceInNewDraft() {
        let destination = store.destination(for: nil)
        store.save(ChatSourceSelection(selectedPackIDs: ["pack"]), for: nil)
        store.remove(nil)
        let fresh = ChatSourceSelection(selectedCollectionIDs: ["new-folder"])
        store.save(fresh, for: nil)

        XCTAssertNil(store.resolve(destination))
        XCTAssertEqual(store.selection(for: nil), fresh)
    }

    func testGenerationSnapshotRemainsStableWhenChatSelectionChanges() {
        var selected = ChatSourceSelection(
            selectedPackIDs: ["pack"], selectedCollectionIDs: ["notes"])
        let snapshot = selected
        selected.setPack("pack", enabled: false)
        selected.setCollection("notes", enabled: false)
        selected.setCollection("later", enabled: true)

        XCTAssertTrue(snapshot.includesPack("pack"))
        XCTAssertTrue(snapshot.includesCollection("notes"))
        XCTAssertFalse(snapshot.includesCollection("later"))
        XCTAssertFalse(selected.includesPack("pack"))
        XCTAssertFalse(selected.includesCollection("notes"))
    }

    func testRemovingChatDoesNotRemoveAnotherChatOrDraftSelection() {
        let chat = UUID()
        let other = UUID()
        let selected = ChatSourceSelection(selectedPackIDs: ["pack"])
        store.save(selected, for: chat)
        store.save(selected, for: other)
        store.save(selected, for: nil)
        store.remove(chat)

        XCTAssertNil(store.selection(for: chat))
        XCTAssertEqual(store.selection(for: other), selected)
        XCTAssertEqual(store.selection(for: nil), selected)
    }
}
