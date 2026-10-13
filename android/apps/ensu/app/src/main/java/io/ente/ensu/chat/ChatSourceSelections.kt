package io.ente.ensu.chat

internal interface ChatSourceSelectionStorage {
    fun read(key: String): ChatSourceSelection?

    fun write(key: String, selection: ChatSourceSelection)

    fun remove(key: String)
}

/** Resolves work started in a draft to that draft's eventual chat, even after navigation. */
internal class ChatSourceSelections(private val storage: ChatSourceSelectionStorage) {
    private val promotedDrafts = mutableMapOf<String, String>()

    fun initialize(
        key: String,
        inventoryReady: Boolean = true,
        defaults: () -> ChatSourceSelection,
    ): ChatSourceSelection =
        storage.read(key) ?: defaults().also { if (inventoryReady) storage.write(key, it) }

    fun promote(draftKey: String, sessionId: String) {
        storage.read(draftKey)?.let { storage.write(sessionId, it) }
        promotedDrafts[draftKey] = sessionId
        storage.remove(draftKey)
    }

    fun selectAdded(
        target: String,
        transform: (ChatSourceSelection) -> ChatSourceSelection,
    ): Pair<String, ChatSourceSelection>? {
        val destination = promotedDrafts[target] ?: target
        // Discarded drafts and deleted chats must not be recreated by asynchronous work.
        val current = storage.read(destination) ?: return null
        val updated = transform(current)
        storage.write(destination, updated)
        return destination to updated
    }
}
