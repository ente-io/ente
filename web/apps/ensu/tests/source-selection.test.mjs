import assert from "node:assert/strict";
import test from "node:test";
import { ChatSourceSelectionStore } from "../src/services/chat/source-selection.ts";

const defaults = { packIds: ["wiki"], noteCollectionIds: ["journal"] };
const makeStorage = () => {
    /** @type {Map<string, string>} */
    const entries = new Map();
    /** @type {Pick<Storage, "getItem" | "setItem" | "removeItem">} */
    const storage = {
        getItem: (key) => entries.get(key) ?? null,
        setItem: (key, value) => entries.set(key, value),
        removeItem: (key) => entries.delete(key),
    };
    return storage;
};

void test("new chats select current sources once and do not inherit later additions", () => {
    const store = new ChatSourceSelectionStore();
    store.initialize("first", defaults);
    const later = {
        packIds: ["wiki", "books"],
        noteCollectionIds: ["journal", "work"],
    };
    store.initialize("first", later);
    store.initialize("second", later);
    assert.deepEqual(store.get("first"), defaults);
    assert.deepEqual(store.get("second"), later);
});

void test("empty selections survive restart and subsequent inventory changes", () => {
    const storage = makeStorage();
    const store = new ChatSourceSelectionStore(storage);
    store.initialize("chat", defaults);
    store.setEnabled("chat", "packIds", "wiki", false);
    store.setEnabled("chat", "noteCollectionIds", "journal", false);
    const reopened = new ChatSourceSelectionStore(storage);
    reopened.initialize("chat", defaults);
    assert.deepEqual(reopened.get("chat"), {
        packIds: [],
        noteCollectionIds: [],
    });
});

void test("switching chats preserves each explicit selection", () => {
    const store = new ChatSourceSelectionStore();
    store.initialize("one", defaults);
    store.initialize("two", defaults);
    store.setEnabled("one", "packIds", "wiki", false);
    store.setEnabled("two", "noteCollectionIds", "journal", false);
    assert.deepEqual(store.get("one"), {
        packIds: [],
        noteCollectionIds: ["journal"],
    });
    assert.deepEqual(store.get("two"), {
        packIds: ["wiki"],
        noteCollectionIds: [],
    });
});

void test("downloads started in a draft follow it into its newly created chat", () => {
    const storage = makeStorage();
    const store = new ChatSourceSelectionStore(storage);
    store.initialize("draft:one", defaults);
    store.transferDraft("draft:one", "chat-one");
    store.initialize("draft:two", defaults);
    store.setEnabled("draft:one", "packIds", "books", true);
    assert.deepEqual(store.get("chat-one")?.packIds, ["wiki", "books"]);
    assert.deepEqual(store.get("draft:two"), defaults);
    assert.deepEqual(
        new ChatSourceSelectionStore(storage).get("chat-one")?.packIds,
        ["wiki", "books"],
    );
});

void test("folder adds completed in an abandoned draft do not alter the next draft", () => {
    const store = new ChatSourceSelectionStore();
    store.initialize("draft:old", defaults);
    store.initialize("draft:new", defaults);
    store.setEnabled("draft:old", "noteCollectionIds", "work", true);
    assert.deepEqual(store.get("draft:new"), defaults);
});

void test("an in-flight generation snapshot is unchanged by later selections", () => {
    const store = new ChatSourceSelectionStore();
    store.initialize("chat", defaults);
    const snapshot = store.get("chat");
    store.setEnabled("chat", "packIds", "wiki", false);
    store.setEnabled("chat", "noteCollectionIds", "work", true);
    assert.deepEqual(snapshot, defaults);
});

void test("late download completion cannot resurrect a deleted chat's selection", () => {
    const storage = makeStorage();
    const store = new ChatSourceSelectionStore(storage);
    store.initialize("draft:one", defaults);
    store.transferDraft("draft:one", "chat");
    store.remove("chat");
    store.setEnabled("draft:one", "packIds", "books", true);
    assert.equal(store.get("chat"), undefined);
    assert.equal(new ChatSourceSelectionStore(storage).get("chat"), undefined);
});

void test("malformed persisted choices safely initialize from current inventory", () => {
    const storage = makeStorage();
    storage.setItem("ensu.desktop.chatSources.chat", '{"packIds":null}');
    const store = new ChatSourceSelectionStore(storage);
    store.initialize("chat", defaults);
    assert.deepEqual(store.get("chat"), defaults);
});
