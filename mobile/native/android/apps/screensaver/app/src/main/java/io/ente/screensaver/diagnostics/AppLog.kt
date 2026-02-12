package io.ente.photos.screensaver.diagnostics

import android.content.Context
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.ArrayDeque
import java.util.Date
import java.util.Locale

object AppLog {

    private const val MAX_ENTRIES = 200
    private const val MAX_PERSISTED_BYTES = 256 * 1024L
    private const val LOG_FILE_NAME = "diagnostics.log"

    private val entries = ArrayDeque<String>()
    private val formatter = SimpleDateFormat("HH:mm:ss", Locale.US)

    @Volatile
    private var logFile: File? = null

    @Volatile
    private var loadedFromDisk: Boolean = false

    private val enteUriHostRegex = Regex("ente://[^/\\s]+")
    private val tokenQueryRegex = Regex("([?&]t=)[^&#\\s]+")
    private val urlFragmentRegex = Regex("#[^\\s]+")
    private val base64TokenRegex = Regex("(?i)(accessTokenJWT|jwtToken|accessToken)=([A-Za-z0-9+/=_-]{12,})")

    fun initialize(context: Context) {
        val file = File(context.applicationContext.filesDir, LOG_FILE_NAME)
        synchronized(entries) {
            if (logFile == null) {
                logFile = file
            }
            if (loadedFromDisk) {
                return
            }
            loadedFromDisk = true

            val existing = runCatching {
                file.takeIf { it.exists() }?.readLines().orEmpty()
            }.getOrDefault(emptyList())

            if (existing.isNotEmpty()) {
                entries.clear()
                existing.takeLast(MAX_ENTRIES).forEach { entries.addLast(it) }
            }
        }
    }

    fun info(tag: String, message: String) {
        add("INFO", tag, message, null)
    }

    fun error(tag: String, message: String, error: Throwable? = null) {
        add("ERROR", tag, message, error)
    }

    fun dump(emptyMessage: String = "No recent logs."): String = synchronized(entries) {
        if (entries.isEmpty()) emptyMessage else entries.joinToString("\n")
    }

    fun clear() {
        synchronized(entries) { entries.clear() }
        runCatching { logFile?.delete() }
    }

    private fun add(level: String, tag: String, message: String, error: Throwable?) {
        val suffix = error?.let {
            val detail = it.message ?: "no message"
            " (${it::class.java.simpleName}: $detail)"
        } ?: ""

        val line = synchronized(entries) {
            val timestamp = formatter.format(Date())
            val rawLine = "$timestamp $level [$tag] $message$suffix"
            val redactedLine = redact(rawLine)

            if (entries.size >= MAX_ENTRIES) {
                entries.removeFirst()
            }
            entries.addLast(redactedLine)

            redactedLine
        }

        persist(line)

        if (level == "ERROR") {
            Log.e("SSaver", line, error)
        } else {
            Log.d("SSaver", line)
        }
    }

    private fun persist(line: String) {
        val file = logFile ?: return
        runCatching {
            file.parentFile?.mkdirs()
            file.appendText(line + "\n")
            if (file.length() <= MAX_PERSISTED_BYTES) {
                return@runCatching
            }

            val tail = file.readLines().takeLast(MAX_ENTRIES)
            file.writeText(tail.joinToString("\n"))
            if (tail.isNotEmpty()) {
                file.appendText("\n")
            }
        }
    }

    private fun redact(input: String): String {
        return input
            .replace(enteUriHostRegex, "ente://***")
            .replace(tokenQueryRegex, "$1***")
            .replace(urlFragmentRegex, "#***")
            .replace(base64TokenRegex) { m -> "${m.groupValues[1]}=***" }
    }
}
