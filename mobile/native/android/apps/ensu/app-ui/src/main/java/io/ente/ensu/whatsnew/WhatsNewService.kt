package io.ente.ensu.whatsnew

import android.content.Context

data class PendingWhatsNew(
    val version: Int,
    val entries: List<WhatsNewEntry>
)

class WhatsNewService(context: Context) {
    private val preferences = context.getSharedPreferences(
        PREFERENCES_NAME,
        Context.MODE_PRIVATE
    )

    fun getPendingWhatsNew(): PendingWhatsNew? {
        val seenVersion = if (preferences.contains(KEY_SEEN_VERSION)) {
            preferences.getInt(KEY_SEEN_VERSION, WhatsNewContent.VERSION)
        } else {
            0
        }
        if (seenVersion >= WhatsNewContent.VERSION) return null

        if (WhatsNewContent.entries.isEmpty()) {
            markSeen()
            return null
        }

        return PendingWhatsNew(
            version = WhatsNewContent.VERSION,
            entries = WhatsNewContent.entries
        )
    }

    fun markSeen() {
        preferences.edit()
            .putInt(KEY_SEEN_VERSION, WhatsNewContent.VERSION)
            .apply()
    }

    private companion object {
        const val PREFERENCES_NAME = "ensu_whats_new"
        const val KEY_SEEN_VERSION = "seen_version"
    }
}
