package io.ente.photos.screensaver.ente

import android.content.Context
import java.io.File
import java.security.MessageDigest

class EnteImageCache(
    private val appContext: Context,
) {

    private val baseDir: File = File(appContext.cacheDir, "ente")

    fun imageFile(accessToken: String, fileId: Long): File {
        val dir = File(baseDir, sha256Hex(accessToken))
        return File(dir, "$fileId.img")
    }

    fun imageMetaFile(accessToken: String, fileId: Long): File {
        val dir = File(baseDir, sha256Hex(accessToken))
        return File(dir, "$fileId.img.meta")
    }

    fun previewFile(accessToken: String, fileId: Long): File {
        val dir = File(baseDir, sha256Hex(accessToken))
        return File(dir, "$fileId.preview")
    }

    fun previewMetaFile(accessToken: String, fileId: Long): File {
        val dir = File(baseDir, sha256Hex(accessToken))
        return File(dir, "$fileId.preview.meta")
    }

    fun ensureDirs(file: File) {
        file.parentFile?.mkdirs()
    }

    fun readUpdateTime(metaFile: File): Long? {
        if (!metaFile.exists()) return null
        return runCatching { metaFile.readText().trim().toLong() }.getOrNull()
    }

    fun writeUpdateTime(metaFile: File, updatedAt: Long) {
        if (updatedAt <= 0L) return
        runCatching { metaFile.writeText(updatedAt.toString()) }
    }

    fun clear(accessToken: String) {
        val dir = File(baseDir, sha256Hex(accessToken))
        if (!dir.exists()) return
        runCatching { dir.deleteRecursively() }
    }

    fun prune(accessToken: String, maxFiles: Int = 500) {
        val dir = File(baseDir, sha256Hex(accessToken))
        if (!dir.exists() || !dir.isDirectory) return

        val files = dir.listFiles()?.filter { it.isFile && !it.name.endsWith(".meta") } ?: return
        if (files.size <= maxFiles) return

        val sorted = files.sortedBy { it.lastModified() }
        val toDelete = sorted.take(files.size - maxFiles)
        toDelete.forEach {
            runCatching { it.delete() }
            runCatching { File(it.parentFile, it.name + ".meta").delete() }
        }
    }

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return digest.joinToString("") { b -> "%02x".format(b) }
    }
}
