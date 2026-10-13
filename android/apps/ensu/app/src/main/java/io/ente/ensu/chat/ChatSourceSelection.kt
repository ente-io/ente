package io.ente.ensu.chat

/** Explicit stable IDs keep later additions from changing an existing chat. */
data class ChatSourceSelection(
    val selectedPackIds: Set<String> = emptySet(),
    val selectedFolderIds: Set<String> = emptySet(),
) {
    fun isPackEnabled(id: String): Boolean = id in selectedPackIds

    fun isFolderEnabled(id: String): Boolean = id in selectedFolderIds

    fun withPackEnabled(id: String, enabled: Boolean): ChatSourceSelection =
        copy(selectedPackIds = if (enabled) selectedPackIds + id else selectedPackIds - id)

    fun withFolderEnabled(id: String, enabled: Boolean): ChatSourceSelection =
        copy(selectedFolderIds = if (enabled) selectedFolderIds + id else selectedFolderIds - id)
}
