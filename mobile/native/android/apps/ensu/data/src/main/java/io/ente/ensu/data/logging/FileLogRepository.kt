package io.ente.ensu.data.logging

import android.content.Context
import android.util.Log
import io.ente.ensu.domain.logging.LogRepository
import io.ente.ensu.domain.model.LogEntry
import io.ente.ensu.domain.model.LogLevel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class FileLogRepository(
    private val context: Context,
    private val maxLogFiles: Int = 5,
    private val maxEntriesInMemory: Int = 500
) : LogRepository {

    private val ioScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val writeMutex = Mutex()

    private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    private val lineTimestampFormatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)

    private val logsDir: File = File(context.filesDir, "logs")

    private val _logs = MutableStateFlow<List<LogEntry>>(emptyList())
    override val logs: StateFlow<List<LogEntry>> = _logs.asStateFlow()

    init {
        ensureLogDir()
        pruneOldLogFiles()
    }

    override fun log(level: LogLevel, message: String, details: String?, tag: String?, throwable: Throwable?) {
        val resolvedTag = tag ?: "ensu"
        val combinedDetails = buildString {
            if (!details.isNullOrBlank()) {
                append(details)
            }
            if (throwable != null) {
                if (isNotEmpty()) append("\n")
                append(throwable.stackTraceToString())
            }
        }.ifBlank { null }

        val safeMessage = LogSanitizer.sanitize(message).orEmpty()
        val safeDetails = LogSanitizer.sanitize(combinedDetails)

        val entry = LogEntry(
            id = UUID.randomUUID().toString(),
            timestampMillis = System.currentTimeMillis(),
            level = level,
            tag = resolvedTag,
            message = safeMessage,
            details = safeDetails
        )

        _logs.update { (listOf(entry) + it).take(maxEntriesInMemory) }

        // Also mirror to Logcat.
        when (level) {
            LogLevel.Info -> Log.i(resolvedTag, safeMessage)
            LogLevel.Warning -> Log.w(resolvedTag, safeMessage)
            LogLevel.Error -> {
                if (throwable != null) {
                    Log.e(resolvedTag, safeMessage, throwable)
                } else {
                    Log.e(resolvedTag, safeMessage)
                }
            }
        }

        val line = formatLine(entry)
        ioScope.launch {
            writeMutex.withLock {
                val file = todayLogFile()
                file.parentFile?.mkdirs()
                file.appendText(line)
            }
        }
    }

    fun logDirectory(): File = logsDir

    fun listLogFiles(): List<File> {
        ensureLogDir()
        return logsDir.listFiles()
            ?.filter { it.isFile && it.name.endsWith(".txt") }
            ?.sortedBy { it.name }
            .orEmpty()
    }

    suspend fun readLogText(file: File): String = withContext(Dispatchers.IO) {
        writeMutex.withLock {
            if (!file.exists()) return@withLock ""
            runCatching { file.readText() }.getOrDefault("")
        }
    }

    fun todayLogFile(): File {
        val name = "${dateFormatter.format(Date())}.txt"
        return File(logsDir, name)
    }

    suspend fun readTodayLogText(): String = withContext(Dispatchers.IO) {
        writeMutex.withLock {
            val file = todayLogFile()
            if (!file.exists()) return@withLock ""
            runCatching { file.readText() }.getOrDefault("")
        }
    }

    suspend fun readTodayEntries(): List<LogEntry> = withContext(Dispatchers.IO) {
        parseLogEntries(readTodayLogText()).reversed()
    }

    suspend fun createLogsZip(outputDir: File = context.cacheDir): File = withContext(Dispatchers.IO) {
        ensureLogDir()
        pruneOldLogFiles()

        val now = Date()
        val out = File(outputDir, "ensu-logs-${dateFormatter.format(now)}-${System.currentTimeMillis()}.zip")
        if (out.exists()) out.delete()

        ZipOutputStream(BufferedOutputStream(FileOutputStream(out))).use { zipOut ->
            logsDir.listFiles()?.sortedBy { it.name }?.forEach { file ->
                if (!file.isFile) return@forEach
                val entry = ZipEntry(file.name)
                zipOut.putNextEntry(entry)
                BufferedInputStream(FileInputStream(file)).use { input ->
                    input.copyTo(zipOut)
                }
                zipOut.closeEntry()
            }
        }
        out
    }

    private fun ensureLogDir() {
        if (!logsDir.exists()) {
            logsDir.mkdirs()
        }
    }

    private fun pruneOldLogFiles() {
        val files = logsDir.listFiles()?.toList().orEmpty()
            .filter { it.isFile && it.name.endsWith(".txt") }
            .mapNotNull { file ->
                val name = file.name.removeSuffix(".txt")
                val date = runCatching { dateFormatter.parse(name) }.getOrNull() ?: return@mapNotNull null
                file to date.time
            }
            .sortedBy { it.second }
            .map { it.first }

        if (files.size <= maxLogFiles) return
        val toDelete = files.take(files.size - maxLogFiles)
        toDelete.forEach { runCatching { it.delete() } }
    }

    private fun formatLine(entry: LogEntry): String {
        val timestamp = lineTimestampFormatter.format(Date(entry.timestampMillis))
        val header = "[${entry.tag}][${entry.level.name.uppercase()}] [$timestamp]"
        val details = entry.details.orEmpty()
        val shouldInline = entry.level == LogLevel.Info && details.isNotBlank() && !looksLikeStackTrace(details)
        val message = entry.message
        var out = "$header $message".trimEnd() + "\n"

        if (details.isNotBlank()) {
            if (shouldInline) {
                val inline = inlineDetails(details)
                if (inline.isNotBlank()) {
                    out += "$inline\n"
                }
            } else {
                details.lines().forEach { line ->
                    out += "$line\n"
                }
            }
        }
        return out
    }

    private fun inlineDetails(details: String): String {
        return details.lineSequence()
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .joinToString(" | ")
    }

    private fun looksLikeStackTrace(details: String): Boolean {
        return details.lineSequence()
            .map { it.trimStart() }
            .any { isStackTraceLine(it) }
    }

    private fun isStackTraceLine(line: String): Boolean {
        val trimmed = line.trimStart()
        return trimmed.startsWith("at ") ||
            trimmed.startsWith("...") ||
            trimmed.startsWith("Caused by") ||
            trimmed.startsWith("Suppressed:")
    }

    private fun parseLogEntries(text: String): List<LogEntry> {
        if (text.isBlank()) return emptyList()

        val entries = mutableListOf<LogEntry>()
        var current: LogEntry? = null
        var details = mutableListOf<String>()

        text.lineSequence().forEach { line ->
            val trimmed = line.trimEnd()
            if (trimmed.isBlank()) return@forEach

            val match = logLineRegex.matchEntire(trimmed)
            if (match == null) {
                if (current != null) {
                    details.add(trimmed)
                } else if (entries.isNotEmpty() && shouldAttachToPrevious(trimmed)) {
                    appendDetailToLast(entries, trimmed)
                } else {
                    entries.add(
                        LogEntry(
                            id = UUID.randomUUID().toString(),
                            timestampMillis = System.currentTimeMillis(),
                            level = LogLevel.Info,
                            tag = "Log",
                            message = trimmed,
                            details = null
                        )
                    )
                }
                return@forEach
            }

            val tag = match.groupValues[1]
            val levelValue = match.groupValues[2]
            val timestampValue = match.groupValues[3]
            val message = match.groupValues[4]
            val trimmedMessage = message.trimStart()
            val isDetail = isDetailLine(trimmedMessage)
            if (isDetail) {
                val cleaned = when {
                    trimmedMessage.startsWith("->") -> trimmedMessage.removePrefix("->").trim()
                    trimmedMessage.startsWith("⤷") -> trimmedMessage.removePrefix("⤷").trim()
                    else -> trimmedMessage
                }
                if (current != null) {
                    details.add(cleaned)
                } else if (entries.isNotEmpty() && shouldAttachToPrevious(cleaned)) {
                    appendDetailToLast(entries, cleaned)
                } else {
                    entries.add(
                        LogEntry(
                            id = UUID.randomUUID().toString(),
                            timestampMillis = System.currentTimeMillis(),
                            level = LogLevel.Info,
                            tag = "Log",
                            message = cleaned,
                            details = null
                        )
                    )
                }
                return@forEach
            }

            current?.let {
                val detailText = details.takeIf { it.isNotEmpty() }?.joinToString("\n")
                entries.add(it.copy(details = detailText))
            }

            val level = parseLevel(levelValue) ?: LogLevel.Info
            val timestamp = runCatching {
                lineTimestampFormatter.parse(timestampValue)?.time
            }.getOrNull() ?: System.currentTimeMillis()

            current = LogEntry(
                id = UUID.randomUUID().toString(),
                timestampMillis = timestamp,
                level = level,
                tag = tag,
                message = message,
                details = null
            )
            details = mutableListOf()
        }

        current?.let {
            val detailText = details.takeIf { it.isNotEmpty() }?.joinToString("\n")
            entries.add(it.copy(details = detailText))
        }

        return entries
    }

    private fun appendDetailToLast(entries: MutableList<LogEntry>, line: String) {
        if (entries.isEmpty()) return
        val last = entries.removeAt(entries.lastIndex)
        val updatedDetails = listOfNotNull(last.details?.takeIf { it.isNotBlank() }, line)
            .joinToString("\n")
        entries.add(last.copy(details = updatedDetails))
    }

    private fun shouldAttachToPrevious(line: String): Boolean {
        if (line.isBlank()) return false
        val trimmed = line.trimStart()
        return line.firstOrNull()?.isWhitespace() == true || isStackTraceLine(trimmed)
    }

    private fun parseLevel(value: String): LogLevel? = when (value.uppercase()) {
        "INFO" -> LogLevel.Info
        "WARNING", "WARN" -> LogLevel.Warning
        "ERROR" -> LogLevel.Error
        else -> null
    }

    private fun isDetailLine(message: String): Boolean {
        val trimmed = message.trimStart()
        return trimmed.startsWith("->") ||
            trimmed.startsWith("⤷") ||
            trimmed.startsWith("at ") ||
            trimmed.startsWith("...") ||
            trimmed.startsWith("Caused by") ||
            trimmed.startsWith("Suppressed:")
    }

    companion object {
        private val logLineRegex = Regex("\\[(.+?)]\\[(.+?)] \\[(.+?)]\\] (.*)")
    }
}
