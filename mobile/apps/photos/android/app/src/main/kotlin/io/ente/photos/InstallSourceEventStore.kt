package io.ente.photos

import android.content.Context
import android.content.pm.PackageInfo
import android.os.Build
import java.net.URLDecoder
import java.util.UUID
import org.json.JSONObject

data class InstallSource(
    val channel: String,
    val platform: String,
    val referrerParams: Map<String, String>,
) {
    val hasReferrer: Boolean get() = referrerParams.isNotEmpty()
}

class InstallSourceEventStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("install_source_state", Context.MODE_PRIVATE)

    fun sourceFromState(): InstallSource? {
        val sourceJson = prefs.getString(KEY_SOURCE, null) ?: return null
        return runCatching {
            val json = JSONObject(sourceJson)
            val paramsJson = json.optJSONObject("referrer_params")
            val params = buildMap {
                paramsJson?.keys()?.forEach { key ->
                    put(key, paramsJson.optString(key))
                }
            }
            InstallSource(
                channel = json.optString("channel", channelForPackage()),
                platform = json.optString("platform", PLATFORM_ANDROID),
                referrerParams = params,
            )
        }.getOrNull()
    }

    fun fallbackSource(channel: String = channelForPackage()): InstallSource = InstallSource(
        channel = channel,
        platform = PLATFORM_ANDROID,
        referrerParams = emptyMap(),
    )

    fun playSource(
        referrer: String?,
    ): InstallSource = InstallSource(
        channel = CHANNEL_PLAYSTORE,
        platform = PLATFORM_ANDROID,
        referrerParams = parseReferrerParams(referrer),
    )

    fun saveSource(source: InstallSource) {
        prefs.edit()
            .putString(KEY_SOURCE, source.toJson().toString())
            .putInt(
                KEY_FLAGS,
                flags.withFlag(FLAG_SOURCE_PRESENT, source.hasReferrer) or FLAG_SOURCE_RESOLVED
            )
            .apply()
    }

    fun logInstallSource(source: InstallSource): String? {
        if (flags.hasFlag(FLAG_INSTALL_EVENT_LOGGED)) {
            return null
        }
        val installSourceId = prefs.getString(KEY_INSTALL_SOURCE_ID, null) ?: UUID.randomUUID().toString()
        val eventJson = buildEvent(source, installSourceId).toString()
        prefs.edit()
            .putString(KEY_SOURCE, source.toJson().toString())
            .putString(KEY_INSTALL_SOURCE_ID, installSourceId)
            .putInt(
                KEY_FLAGS,
                flags.withFlag(FLAG_SOURCE_PRESENT, source.hasReferrer) or
                    FLAG_SOURCE_RESOLVED or
                    FLAG_INSTALL_EVENT_LOGGED
            )
            .putInt(KEY_SCHEMA_VERSION, 1)
            .apply()
        return eventJson
    }

    fun channelForPackage(): String {
        val packageName = context.packageName.removeSuffix(".debug")
        return when (packageName) {
            "io.ente.photos" -> CHANNEL_PLAYSTORE
            "io.ente.photos.fdroid" -> "fdroid"
            "io.ente.photos.independent" -> "github"
            "io.ente.photos.dev" -> "dev"
            else -> "unknown"
        }
    }

    private fun buildEvent(source: InstallSource, installSourceId: String): JSONObject {
        val packageInfo = packageInfo()
        return JSONObject()
            .put("event", "install_source")
            .put("install_source_id", installSourceId)
            .put("event_type", "install")
            .put("app", "photos")
            .put("platform", source.platform)
            .put("channel", source.channel)
            .put("package_name", context.packageName)
            .put("app_version", packageInfo?.versionName.orEmpty())
            .put("build_number", packageInfo?.buildNumber().orEmpty())
            .put("referrer", JSONObject().put("params", JSONObject(source.referrerParams)))
    }

    private fun parseReferrerParams(referrer: String?): Map<String, String> {
        val query = referrer?.trim()?.removePrefix("?")
        if (query.isNullOrEmpty()) {
            return emptyMap()
        }
        return runCatching {
            query.split("&")
                .asSequence()
                .filter { it.isNotBlank() }
                .mapNotNull { part ->
                    val separator = part.indexOf("=")
                    val key = if (separator >= 0) part.substring(0, separator) else part
                    val value = if (separator >= 0) part.substring(separator + 1) else ""
                    val decodedKey = key.urlDecode()
                    if (decodedKey.isEmpty()) {
                        null
                    } else {
                        decodedKey to value.urlDecode()
                    }
                }
                .toMap()
        }.getOrDefault(emptyMap())
    }

    private fun InstallSource.toJson(): JSONObject = JSONObject()
        .put("channel", channel)
        .put("platform", platform)
        .put("referrer_params", JSONObject(referrerParams))

    private fun String.urlDecode(): String =
        URLDecoder.decode(this, Charsets.UTF_8.name())

    private fun packageInfo(): PackageInfo? =
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0) }.getOrNull()

    @Suppress("DEPRECATION")
    private fun PackageInfo.buildNumber(): String =
        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) longVersionCode else versionCode.toLong()).toString()

    private val flags: Int get() = prefs.getInt(KEY_FLAGS, 0)

    private fun Int.hasFlag(flag: Int): Boolean = this and flag != 0

    private fun Int.withFlag(flag: Int, enabled: Boolean): Int =
        if (enabled) this or flag else this and flag.inv()

    companion object {
        private const val CHANNEL_PLAYSTORE = "playstore"
        private const val FLAG_SOURCE_PRESENT = 1 shl 0
        private const val FLAG_SOURCE_RESOLVED = 1 shl 1
        private const val FLAG_INSTALL_EVENT_LOGGED = 1 shl 2
        private const val KEY_FLAGS = "flags"
        private const val KEY_INSTALL_SOURCE_ID = "install_source_id"
        private const val KEY_SCHEMA_VERSION = "schema_version"
        private const val KEY_SOURCE = "source"
        private const val PLATFORM_ANDROID = "android"
    }
}
