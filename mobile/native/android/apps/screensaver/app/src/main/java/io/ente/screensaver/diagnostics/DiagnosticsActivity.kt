@file:Suppress("PackageDirectoryMismatch")

package io.ente.screensaver.diagnostics

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.method.ScrollingMovementMethod
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.ente.screensaver.R
import io.ente.screensaver.databinding.ActivityDiagnosticsBinding
import io.ente.screensaver.dream.PhotoDreamService

class DiagnosticsActivity : AppCompatActivity() {

    private lateinit var binding: ActivityDiagnosticsBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppLog.initialize(this)
        binding = ActivityDiagnosticsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.textReport.movementMethod = ScrollingMovementMethod()
        binding.textLogs.text = dumpLogs()

        binding.buttonRefresh.setOnClickListener {
            binding.textLogs.text = dumpLogs()
            binding.textReport.text = buildReport()
        }

        binding.buttonSetScreensaver.setOnClickListener {
            val result = ScreensaverConfigurator.trySetAsScreensaver(this)
            val report = buildReport()
            when (result) {
                is ScreensaverConfigurator.Result.Success -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                    binding.textReport.text = report
                }

                is ScreensaverConfigurator.Result.NeedsWriteSecureSettings -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                    binding.textReport.text = buildString {
                        append(report)
                        append("\n\n")
                        append(result.message)
                    }
                }

                is ScreensaverConfigurator.Result.Error -> {
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                    binding.textReport.text = buildString {
                        append(report)
                        append("\n\n")
                        append(result.details)
                    }
                }
            }
            binding.textLogs.text = dumpLogs()
        }

        binding.textLogs.text = dumpLogs()
        binding.textReport.text = buildReport()
    }

    private fun dumpLogs(): String {
        return AppLog.dump(getString(R.string.diagnostics_no_recent_logs))
    }

    private fun buildReport(): String {
        val sb = StringBuilder()

        val dreamComponent = ComponentName(this, PhotoDreamService::class.java).flattenToString()

        sb.appendLine(getString(R.string.diagnostics_report_title))
        sb.appendLine(getString(R.string.diagnostics_report_separator))
        sb.appendLine(getString(R.string.diagnostics_report_device, Build.MANUFACTURER, Build.MODEL))
        sb.appendLine(getString(R.string.diagnostics_report_android, Build.VERSION.RELEASE, Build.VERSION.SDK_INT))
        sb.appendLine(getString(R.string.diagnostics_report_dream_component, dreamComponent))
        sb.appendLine()

        val dreamSettingsIntent = Intent(Settings.ACTION_DREAM_SETTINGS)
        val dreamSettingsResolvable = dreamSettingsIntent.resolveActivity(packageManager) != null
        sb.appendLine(
            getString(
                R.string.diagnostics_report_action_dream_settings_resolvable,
                yesNo(dreamSettingsResolvable),
            ),
        )

        val tvSettingsIntent = Intent(Intent.ACTION_MAIN).addCategory("android.intent.category.LEANBACK_SETTINGS")
        val tvSettingsResolvable = tvSettingsIntent.resolveActivity(packageManager) != null
        sb.appendLine(
            getString(
                R.string.diagnostics_report_leanback_settings_resolvable,
                yesNo(tvSettingsResolvable),
            ),
        )

        val tvDaydreamIntent = Intent().setClassName(
            "com.android.tv.settings",
            "com.android.tv.settings.device.display.daydream.DaydreamActivity",
        )
        val tvDaydreamResolvable = tvDaydreamIntent.resolveActivity(packageManager) != null
        sb.appendLine(
            getString(
                R.string.diagnostics_report_tv_daydream_resolvable,
                yesNo(tvDaydreamResolvable),
            ),
        )

        sb.appendLine()
        sb.appendLine(getString(R.string.diagnostics_report_secure_settings))
        val cr = contentResolver
        sb.appendLine(
            getString(
                R.string.diagnostics_report_secure_screensaver_enabled,
                Settings.Secure.getInt(cr, "screensaver_enabled", -1),
            ),
        )
        sb.appendLine(
            getString(
                R.string.diagnostics_report_secure_activate_on_sleep,
                Settings.Secure.getInt(cr, "screensaver_activate_on_sleep", -1),
            ),
        )
        sb.appendLine(
            getString(
                R.string.diagnostics_report_secure_activate_on_dock,
                Settings.Secure.getInt(cr, "screensaver_activate_on_dock", -1),
            ),
        )
        sb.appendLine(
            getString(
                R.string.diagnostics_report_secure_default_component,
                Settings.Secure.getString(cr, "screensaver_default_component") ?: getString(R.string.diagnostics_report_null),
            ),
        )
        sb.appendLine(
            getString(
                R.string.diagnostics_report_secure_components,
                Settings.Secure.getString(cr, "screensaver_components") ?: getString(R.string.diagnostics_report_null),
            ),
        )

        sb.appendLine()

        val dreamServiceIntent = Intent("android.service.dreams.DreamService")
        val resolveInfos = if (Build.VERSION.SDK_INT >= 33) {
            packageManager.queryIntentServices(
                dreamServiceIntent,
                android.content.pm.PackageManager.ResolveInfoFlags.of(android.content.pm.PackageManager.MATCH_ALL.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentServices(dreamServiceIntent, 0)
        }

        sb.appendLine(getString(R.string.diagnostics_report_dream_services_found, resolveInfos.size))
        resolveInfos
            .mapNotNull { it.serviceInfo }
            .sortedWith(compareBy({ it.packageName }, { it.name }))
            .forEach { serviceInfo ->
                val component = "${serviceInfo.packageName}/${serviceInfo.name}"
                sb.appendLine(getString(R.string.diagnostics_report_service_item, component))
            }

        return sb.toString().trimEnd()
    }

    private fun yesNo(value: Boolean): String {
        return getString(if (value) R.string.common_yes else R.string.common_no)
    }
}
