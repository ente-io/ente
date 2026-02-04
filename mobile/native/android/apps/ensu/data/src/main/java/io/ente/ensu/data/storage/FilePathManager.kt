package io.ente.ensu.data.storage

import android.content.Context
import java.io.File

class FilePathManager(context: Context) {
    private val appDataDir: File = ensureDir(context.filesDir)
    val attachmentsDir: File = ensureDir(File(appDataDir, "attachments"))
    val mainDbFile: File = File(appDataDir, "llmchat.db")
    val onlineDbFile: File = File(appDataDir, "llmchat_online.db")
    val syncDbFile: File = File(appDataDir, "llmchat_sync.db")
    val syncBaseDir: File = ensureDir(File(appDataDir, "llmchat"))
    val encryptedAttachmentsDir: File = ensureDir(File(syncBaseDir, "chat_attachments_encrypted"))
    val syncMetaDir: File = ensureDir(File(syncBaseDir, "sync_meta"))
    val plaintextAttachmentsDir: File = attachmentsDir

    private fun ensureDir(dir: File): File {
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }
}
