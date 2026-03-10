package io.ente.ensu.domain.store

import io.ente.ensu.domain.llm.DownloadProgress

internal data class ResolvedDownloadProgress(
    val percent: Int?,
    val status: String,
    val isDownloading: Boolean,
    val isFinished: Boolean
)

internal class DownloadProgressTracker(
    initialPercent: Int? = 0,
    initialStatus: String? = "Starting download..."
) {
    private var lastVisiblePercent: Int? = initialPercent
    private var lastVisibleStatus: String? = initialStatus

    fun resolve(progress: DownloadProgress): ResolvedDownloadProgress {
        val isLoading = progress.status.contains("Loading", ignoreCase = true)
        val isFinished = progress.status.contains("Ready", ignoreCase = true)
        val rawPercent = progress.percent.takeIf { it >= 0 }
        val previousPercent = lastVisiblePercent
        val previousStatus = lastVisibleStatus

        val resolvedPercent = when {
            isFinished -> 100
            rawPercent == null -> previousPercent
            previousPercent == null -> rawPercent
            rawPercent >= previousPercent -> rawPercent
            else -> previousPercent
        }
        val regressed = rawPercent != null &&
            previousPercent != null &&
            rawPercent < previousPercent
        val resolvedStatus = when {
            isFinished || isLoading -> progress.status
            regressed -> previousStatus ?: progress.status
            else -> progress.status
        }

        if (!isFinished) {
            lastVisiblePercent = resolvedPercent
            lastVisibleStatus = resolvedStatus
        }

        return ResolvedDownloadProgress(
            percent = resolvedPercent,
            status = resolvedStatus,
            isDownloading = ((progress.percent in 0..99) || isLoading) && !isFinished,
            isFinished = isFinished
        )
    }
}
