package io.ente.photos.screensaver.ente

import android.content.Context
import androidx.security.crypto.EncryptedFile
import androidx.security.crypto.MasterKey
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap

class EnteImageCache(
    private val appContext: Context,
) {

    private val baseDir: File = File(appContext.cacheDir, "ente")
    private val tokenDirCache = ConcurrentHashMap<String, File>()
    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(appContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    fun imageFile(accessToken: String, fileId: Long): File {
        val dir = tokenDir(accessToken)
        return File(dir, "$fileId.img.enc")
    }

    fun imageLegacyFile(accessToken: String, fileId: Long): File {
        val dir = tokenDir(accessToken)
        return File(dir, "$fileId.img")
    }

    fun imageMetaFile(accessToken: String, fileId: Long): File {
        val dir = tokenDir(accessToken)
        return File(dir, "$fileId.img.meta")
    }

    fun previewFile(accessToken: String, fileId: Long): File {
        val dir = tokenDir(accessToken)
        return File(dir, "$fileId.preview.enc")
    }

    fun previewLegacyFile(accessToken: String, fileId: Long): File {
        val dir = tokenDir(accessToken)
        return File(dir, "$fileId.preview")
    }

    fun previewMetaFile(accessToken: String, fileId: Long): File {
        val dir = tokenDir(accessToken)
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

    fun readEncryptedBytes(file: File): ByteArray? {
        if (!file.exists() || file.length() <= 0L) return null
        return runCatching {
            encryptedFile(file).openFileInput().use { input ->
                input.readBytes()
            }
        }.getOrNull()
    }

    fun writeEncryptedBytes(file: File, bytes: ByteArray) {
        ensureDirs(file)
        val tmp = File(file.parentFile, file.name + ".tmp")
        encryptedFile(tmp).openFileOutput().use { output ->
            output.write(bytes)
        }
        if (!tmp.renameTo(file)) {
            tmp.copyTo(file, overwrite = true)
            tmp.delete()
        }
    }

    fun migrateLegacyFile(legacyFile: File, encryptedFile: File): Boolean {
        if (!legacyFile.exists() || legacyFile.length() <= 0L) return false
        return runCatching {
            if (encryptedFile.exists() && encryptedFile.length() > 0L) {
                legacyFile.delete()
                return@runCatching true
            }
            val bytes = legacyFile.readBytes()
            writeEncryptedBytes(encryptedFile, bytes)
            legacyFile.delete()
            true
        }.getOrDefault(false)
    }

    fun clear(accessToken: String) {
        val dir = tokenDir(accessToken)
        if (!dir.exists()) return
        runCatching { dir.deleteRecursively() }
        tokenDirCache.remove(accessToken)
    }

    fun prune(accessToken: String, maxFiles: Int = 500) {
        val dir = tokenDir(accessToken)
        if (!dir.exists() || !dir.isDirectory) return

        val files = dir.listFiles()?.filter {
            it.isFile &&
                !it.name.endsWith(".meta") &&
                !it.name.endsWith(".tmp")
        } ?: return
        if (files.size <= maxFiles) return

        val sorted = files.sortedBy { it.lastModified() }
        val toDelete = sorted.take(files.size - maxFiles)
        toDelete.forEach {
            runCatching { it.delete() }
            runCatching { pairedMetaFile(it)?.delete() }
        }
    }

    private fun encryptedFile(file: File): EncryptedFile {
        return EncryptedFile.Builder(
            appContext,
            file,
            masterKey,
            EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB,
        ).build()
    }

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return digest.joinToString("") { b -> "%02x".format(b) }
    }

    private fun tokenDir(accessToken: String): File {
        return tokenDirCache.getOrPut(accessToken) {
            File(baseDir, sha256Hex(accessToken))
        }
    }

    private fun pairedMetaFile(cacheFile: File): File? {
        val name = cacheFile.name
        val metaName = when {
            name.endsWith(".img.enc") -> name.removeSuffix(".enc") + ".meta"
            name.endsWith(".preview.enc") -> name.removeSuffix(".enc") + ".meta"
            name.endsWith(".img") || name.endsWith(".preview") -> "$name.meta"
            else -> return null
        }
        return File(cacheFile.parentFile, metaName)
    }
}
