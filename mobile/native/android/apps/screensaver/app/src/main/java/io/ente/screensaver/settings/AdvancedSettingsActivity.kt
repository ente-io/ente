package io.ente.photos.screensaver.settings

import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import io.ente.photos.screensaver.R
import io.ente.photos.screensaver.databinding.ActivityAdvancedSettingsBinding
import io.ente.photos.screensaver.diagnostics.DiagnosticsActivity
import io.ente.photos.screensaver.ente.EntePublicAlbumRepository
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class AdvancedSettingsActivity : AppCompatActivity() {

    private val scope = MainScope()
    private var binding: ActivityAdvancedSettingsBinding? = null
    private var advancedRows: List<TextView> = emptyList()
    private var dividerAboveByRow: Map<TextView, View> = emptyMap()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val viewBinding = ActivityAdvancedSettingsBinding.inflate(layoutInflater)
        binding = viewBinding
        setContentView(viewBinding.root)

        viewBinding.rowDiagnostics.setOnClickListener {
            startActivity(Intent(this, DiagnosticsActivity::class.java))
        }

        viewBinding.rowClearCache.setOnClickListener {
            scope.launch {
                val repo = EntePublicAlbumRepository.get(this@AdvancedSettingsActivity)
                val config = repo.getConfig()
                if (config == null) {
                    Toast.makeText(
                        this@AdvancedSettingsActivity,
                        getString(R.string.ente_cache_clear_none),
                        Toast.LENGTH_LONG,
                    ).show()
                } else {
                    repo.clearCache()
                    Toast.makeText(
                        this@AdvancedSettingsActivity,
                        getString(R.string.ente_cache_cleared),
                        Toast.LENGTH_LONG,
                    ).show()
                }
            }
        }

        advancedRows = listOf(viewBinding.rowClearCache, viewBinding.rowDiagnostics)
        dividerAboveByRow = mapOf(viewBinding.rowDiagnostics to viewBinding.dividerDiagnostics)
        setupRowFocusStyling(advancedRows)

        viewBinding.rowClearCache.post {
            viewBinding.rowClearCache.requestFocus()
            refreshRowTextSizes()
        }
    }

    override fun onResume() {
        super.onResume()
        refreshRowTextSizes()
    }

    private fun setupRowFocusStyling(rows: List<TextView>) {
        rows.forEach { row ->
            row.setTextSize(TypedValue.COMPLEX_UNIT_SP, ROW_TEXT_SIZE_NORMAL_SP)
            row.setOnFocusChangeListener { view, hasFocus ->
                val textView = view as? TextView ?: return@setOnFocusChangeListener
                val textSize = if (hasFocus) {
                    ROW_TEXT_SIZE_FOCUSED_SP
                } else {
                    ROW_TEXT_SIZE_NORMAL_SP
                }
                textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, textSize)
                refreshDividerStyles()
            }
        }
    }

    private fun refreshRowTextSizes() {
        advancedRows.forEach { row ->
            val textSize = if (row.hasFocus()) {
                ROW_TEXT_SIZE_FOCUSED_SP
            } else {
                ROW_TEXT_SIZE_NORMAL_SP
            }
            row.setTextSize(TypedValue.COMPLEX_UNIT_SP, textSize)
        }
        refreshDividerStyles()
    }

    private fun refreshDividerStyles() {
        if (dividerAboveByRow.isEmpty()) return

        val subtleColor = ContextCompat.getColor(this, R.color.ssaver_settings_divider_subtle)
        val strongColor = ContextCompat.getColor(this, R.color.ssaver_settings_divider_strong)

        dividerAboveByRow.values.forEach { divider ->
            divider.setBackgroundColor(subtleColor)
        }

        val visibleRows = advancedRows.filter { it.isShown }
        val focusedIndex = visibleRows.indexOfFirst { it.hasFocus() }
        if (focusedIndex == -1 || focusedIndex >= visibleRows.lastIndex) return

        val nextRow = visibleRows[focusedIndex + 1]
        dividerAboveByRow[nextRow]?.setBackgroundColor(strongColor)
    }

    override fun onDestroy() {
        advancedRows = emptyList()
        dividerAboveByRow = emptyMap()
        binding = null
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val ROW_TEXT_SIZE_NORMAL_SP = 32f
        private const val ROW_TEXT_SIZE_FOCUSED_SP = 36f
    }
}
