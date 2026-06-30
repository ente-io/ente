package io.ente.ensu.storage

import android.content.Context
import java.io.File

class FilePathManager(context: Context) {
    private val appDataDir: File = ensureDir(context.filesDir)
    val attachmentsDir: File = ensureDir(File(appDataDir, "attachments"))
    val mainDbFile: File = File(appDataDir, "llmchat.db")
    val attachmentsDbFile: File = File(appDataDir, "llmchat_sync.db")
    val legacyOnlineDbFile: File = File(appDataDir, "llmchat_online.db")
    val legacySyncDir: File = File(appDataDir, "llmchat")

    private fun ensureDir(dir: File): File {
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }
}
