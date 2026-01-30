package io.ente.ensu.data.storage

import android.content.Context
import java.io.File

class FilePathManager(context: Context) {
    val attachmentsDir: File = ensureDir(File(context.filesDir, "attachments"))
    val mainDbFile: File = File(context.filesDir, "llmchat.db")
    val attachmentsDbFile: File = File(context.filesDir, "llmchat_attachments.db")
    val syncBaseDir: File = ensureDir(File(context.filesDir, "llmchat"))
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
