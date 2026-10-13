package io.ente.ensu.chat

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ChatSourceSelectionsTest {
    private class MemoryStorage : ChatSourceSelectionStorage {
        private val values = mutableMapOf<String, ChatSourceSelection>()

        override fun read(key: String): ChatSourceSelection? = values[key]

        override fun write(key: String, selection: ChatSourceSelection) {
            values[key] = selection
        }

        override fun remove(key: String) {
            values.remove(key)
        }
    }

    @Test
    fun existingChatKeepsItsSnapshotWhenInventoryChangesAndStoreRestarts() {
        val storage = MemoryStorage()
        val original = ChatSourceSelection(setOf("pack-a"), setOf("folder-a"))
        ChatSourceSelections(storage).initialize("chat") { original }
        val restored =
            ChatSourceSelections(storage).initialize("chat") {
                ChatSourceSelection(setOf("pack-a", "pack-b"), setOf("folder-a", "folder-b"))
            }
        assertEquals(original, restored)
        assertFalse(restored.isPackEnabled("pack-b"))
        assertFalse(restored.isFolderEnabled("folder-b"))
    }

    @Test
    fun emptySelectionStaysEmptyAndNewChatGetsCurrentInventory() {
        val storage = MemoryStorage()
        val selections = ChatSourceSelections(storage)
        selections.initialize("old") { ChatSourceSelection() }
        val current = ChatSourceSelection(setOf("pack"), setOf("folder"))
        assertEquals(ChatSourceSelection(), selections.initialize("old") { current })
        assertEquals(current, selections.initialize("new") { current })
    }

    @Test
    fun asyncAdditionFollowsPromotedDraftWithoutAffectingAnotherChat() {
        val storage = MemoryStorage()
        val selections = ChatSourceSelections(storage)
        selections.initialize("draft-1") { ChatSourceSelection() }
        selections.promote("draft-1", "chat-1")
        selections.initialize("draft-2") { ChatSourceSelection() }
        val result = selections.selectAdded("draft-1") { it.withFolderEnabled("new-folder", true) }
        assertEquals("chat-1", result?.first)
        assertTrue(storage.read("chat-1")!!.isFolderEnabled("new-folder"))
        assertFalse(storage.read("draft-2")!!.isFolderEnabled("new-folder"))
        assertNull(storage.read("draft-1"))
    }

    @Test
    fun asyncAdditionDoesNotRecreateDiscardedDraftOrDeletedChat() {
        val storage = MemoryStorage()
        val selections = ChatSourceSelections(storage)
        selections.initialize("draft") { ChatSourceSelection() }
        storage.remove("draft")
        assertNull(selections.selectAdded("draft") { it.withPackEnabled("pack", true) })
        selections.initialize("another-draft") { ChatSourceSelection() }
        selections.promote("another-draft", "chat")
        storage.remove("chat")
        assertNull(selections.selectAdded("another-draft") { it.withPackEnabled("pack", true) })
    }

    @Test
    fun capturedGenerationSelectionIsUnchangedByLaterEditsOrAdditions() {
        val storage = MemoryStorage()
        val selections = ChatSourceSelections(storage)
        val snapshot =
            selections.initialize("chat") { ChatSourceSelection(setOf("pack"), setOf("folder")) }
        storage.write(
            "chat",
            snapshot.withPackEnabled("pack", false).withFolderEnabled("folder", false),
        )
        selections.selectAdded("chat") { it.withPackEnabled("new-pack", true) }
        assertTrue(snapshot.isPackEnabled("pack"))
        assertTrue(snapshot.isFolderEnabled("folder"))
        assertFalse(snapshot.isPackEnabled("new-pack"))
        assertFalse(storage.read("chat")!!.isPackEnabled("pack"))
        assertFalse(storage.read("chat")!!.isFolderEnabled("folder"))
    }

    @Test
    fun incompleteInventoryDoesNotPermanentlyDisableUnknownSources() {
        val storage = MemoryStorage()
        val selections = ChatSourceSelections(storage)
        val partial = ChatSourceSelection(setOf("available-pack"), emptySet())
        assertEquals(partial, selections.initialize("chat", inventoryReady = false) { partial })
        assertNull(storage.read("chat"))

        val complete =
            ChatSourceSelection(setOf("available-pack", "recovered-pack"), setOf("folder"))
        assertEquals(complete, selections.initialize("chat") { complete })
        assertEquals(complete, storage.read("chat"))
    }

    @Test
    fun inventoryFailurePreservesSavedChoicesIncludingAnEmptySelection() {
        val storage = MemoryStorage()
        val selections = ChatSourceSelections(storage)
        val saved = ChatSourceSelection(setOf("unavailable-pack"), setOf("unavailable-folder"))
        selections.initialize("selected") { saved }
        selections.initialize("empty") { ChatSourceSelection() }
        val available = ChatSourceSelection(setOf("other-pack"), setOf("other-folder"))
        assertEquals(saved, selections.initialize("selected", inventoryReady = false) { available })
        assertEquals(
            ChatSourceSelection(),
            selections.initialize("empty", inventoryReady = false) { available },
        )
        assertEquals(saved, storage.read("selected"))
    }
}
