package io.ente.ensu.whatsnew

data class WhatsNewEntry(
    val title: String,
    val description: String
)

object WhatsNewContent {
    const val VERSION: Int = 1

    val entries: List<WhatsNewEntry> = listOf(
        WhatsNewEntry(
            title = "In-app release notes",
            description = "Ensu can now show a short What's new note after updates, with platform-specific entries and a changelog version independent from the app build version."
        )
    )
}
