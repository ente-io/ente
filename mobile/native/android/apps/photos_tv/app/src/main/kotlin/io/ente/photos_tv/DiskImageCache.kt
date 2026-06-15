package io.ente.photos_tv

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.jsonPrimitive
import android.util.Base64
import java.io.File

internal class DiskImageCache(
    context: Context,
    private val maxBytes: Long = IMAGE_CACHE_MAX_BYTES,
) {
    private val directory = File(context.cacheDir, "photos_tv_image_cache")
    private val stateFile = File(directory, STATE_FILE_NAME)
    private var state: CacheState? = null

    init {
        directory.mkdirs()
    }

    fun read(file: CastFile): ByteArray? {
        val name = cacheName(file)
        val loadedState = loadState()
        if (!loadedState.entries.containsKey(name)) return null
        val cacheFile = File(directory, name)
        if (cacheFile.exists()) return cacheFile.readBytes()
        loadedState.entries.remove(name)
        saveState(loadedState)
        return null
    }

    fun markUsed(file: CastFile) {
        val name = cacheName(file)
        val loadedState = loadState()
        val entry = loadedState.entries[name] ?: return
        loadedState.entries[name] = entry.copy(lastUsed = System.currentTimeMillis())
        saveState(loadedState)
    }

    fun write(file: CastFile, bytes: ByteArray) {
        val name = cacheName(file)
        val cacheFile = File(directory, name)
        val tempFile = File(directory, "$name.tmp")
        val loadedState = loadState()
        tempFile.writeBytes(bytes)
        tempFile.renameTo(cacheFile)
        loadedState.entries[name] = CacheEntry(size = bytes.size.toLong(), lastUsed = System.currentTimeMillis())
        enforceLimit(loadedState)
        saveState(loadedState)
    }

    private fun loadState(): CacheState {
        val cachedState = state
        if (cachedState != null) return cachedState
        val loadedState = readState()
        state = loadedState
        return loadedState
    }

    private fun readState(): CacheState {
        if (!stateFile.exists()) return CacheState()
        return runCatching {
            JsonConfig.value.decodeFromString<CacheState>(stateFile.readText())
        }.getOrElse {
            stateFile.delete()
            CacheState()
        }
    }

    private fun saveState(state: CacheState) {
        val tempFile = File(directory, "$STATE_FILE_NAME.tmp")
        tempFile.writeText(JsonConfig.value.encodeToString(state))
        tempFile.renameTo(stateFile)
    }

    private fun enforceLimit(state: CacheState) {
        var totalBytes = state.entries.values.sumOf { it.size }
        val names = state.entries.entries.sortedBy { it.value.lastUsed }.map { it.key }
        for (name in names) {
            if (totalBytes <= maxBytes) return
            val entry = state.entries.remove(name) ?: continue
            File(directory, name).delete()
            totalBytes -= entry.size
        }
    }
}

private fun cacheName(file: CastFile): String {
    val header = file.preview["decryptionHeader"]?.jsonPrimitive?.content.orEmpty()
    val headerKey = Base64.encodeToString(header.encodeToByteArray(), Base64.URL_SAFE or Base64.NO_WRAP)
    return "preview_${file.id}_$headerKey.bin"
}

@Serializable
private data class CacheState(
    val entries: MutableMap<String, CacheEntry> = mutableMapOf(),
)

@Serializable
private data class CacheEntry(
    val size: Long,
    val lastUsed: Long,
)

private const val STATE_FILE_NAME = "cache_state.json"
