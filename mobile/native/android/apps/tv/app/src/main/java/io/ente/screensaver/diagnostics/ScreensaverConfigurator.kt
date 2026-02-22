@file:Suppress("PackageDirectoryMismatch")

package io.ente.photos.screensaver.diagnostics

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.dream.PhotoDreamService

object ScreensaverConfigurator {

    private const val KEY_SCREENSAVER_ENABLED = "screensaver_enabled"
    private const val KEY_SCREENSAVER_ACTIVATE_ON_SLEEP = "screensaver_activate_on_sleep"
    private const val KEY_SCREENSAVER_COMPONENTS = "screensaver_components"
    private const val KEY_SCREENSAVER_DEFAULT_COMPONENT = "screensaver_default_component"

    sealed class Result {
        data class Success(val message: String) : Result()
        data class NeedsWriteSecureSettings(val message: String, val adbInstructions: String) : Result()
        data class Error(val message: String, val details: String) : Result()
    }

    fun trySetAsScreensaver(context: Context): Result {
        val component = ComponentName(context, PhotoDreamService::class.java).flattenToString()
        val contentResolver = context.contentResolver

        return try {
            val okEnabled = Settings.Secure.putInt(contentResolver, KEY_SCREENSAVER_ENABLED, 1)
            val okActivateOnSleep = Settings.Secure.putInt(contentResolver, KEY_SCREENSAVER_ACTIVATE_ON_SLEEP, 1)
            val okDefault = Settings.Secure.putString(contentResolver, KEY_SCREENSAVER_DEFAULT_COMPONENT, component)
            val okComponents = Settings.Secure.putString(contentResolver, KEY_SCREENSAVER_COMPONENTS, component)

            val ok = okEnabled && okActivateOnSleep && okDefault && okComponents
            if (ok) {
                Result.Success(context.getString(R.string.screensaver_set_success))
            } else {
                Result.Error(
                    message = context.getString(R.string.screensaver_set_rejected),
                    details = buildAdbCommands(context),
                )
            }
        } catch (_: SecurityException) {
            Result.NeedsWriteSecureSettings(
                message = context.getString(R.string.screensaver_set_needs_permission),
                adbInstructions = buildAdbCommands(context),
            )
        } catch (t: Throwable) {
            Result.Error(
                message = context.getString(
                    R.string.screensaver_set_failed,
                    t::class.java.simpleName,
                ),
                details = t.message ?: context.getString(R.string.screensaver_set_failed_no_details),
            )
        }
    }

    fun isScreensaverConfigured(context: Context): Boolean {
        val component = ComponentName(context, PhotoDreamService::class.java).flattenToString()
        val cr = context.contentResolver
        val enabled = Settings.Secure.getInt(cr, KEY_SCREENSAVER_ENABLED, 0) == 1
        val defaultComponent = Settings.Secure.getString(cr, KEY_SCREENSAVER_DEFAULT_COMPONENT).orEmpty()
        val components = Settings.Secure.getString(cr, KEY_SCREENSAVER_COMPONENTS).orEmpty()
        return enabled && (defaultComponent == component || components.contains(component))
    }

    fun adbCommands(context: Context): String {
        return buildAdbCommands(context)
    }

    private fun buildAdbCommands(context: Context): String {
        return context.getString(R.string.screensaver_adb_grant_command, context.packageName)
    }
}
