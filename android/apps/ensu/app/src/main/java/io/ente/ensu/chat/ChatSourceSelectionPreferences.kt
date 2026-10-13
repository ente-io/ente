package io.ente.ensu.chat

import android.content.Context
import java.util.UUID

/** Read synchronously to avoid briefly using another chat's choices. */
internal class ChatSourceSelectionPreferences(context: Context) : ChatSourceSelectionStorage {
    private val preferences =
        context.applicationContext.getSharedPreferences("ensu_chat_sources", Context.MODE_PRIVATE)

    var draftKey: String = preferences.getString("draft_key", null) ?: newDraftKey()
        private set

    override fun read(key: String): ChatSourceSelection? {
        if (!preferences.contains("$key.packs")) return null
        return ChatSourceSelection(
            selectedPackIds = preferences.getStringSet("$key.packs", emptySet()).orEmpty().toSet(),
            selectedFolderIds =
                preferences.getStringSet("$key.folders", emptySet()).orEmpty().toSet(),
        )
    }

    override fun write(key: String, selection: ChatSourceSelection) {
        preferences
            .edit()
            .putStringSet("$key.packs", selection.selectedPackIds)
            .putStringSet("$key.folders", selection.selectedFolderIds)
            .apply()
    }

    override fun remove(key: String) {
        preferences.edit().remove("$key.packs").remove("$key.folders").apply()
    }

    fun resetDraft() {
        remove(draftKey)
        draftKey = newDraftKey()
    }

    private fun newDraftKey(): String {
        val key = "draft-${UUID.randomUUID()}"
        preferences.edit().putString("draft_key", key).apply()
        return key
    }
}
