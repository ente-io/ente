package io.ente.ensu.domain.model

enum class AttachmentDownloadStatus {
    Queued,
    Downloading,
    Completed,
    Failed,
    Canceled
}

data class AttachmentDownloadItem(
    val id: String,
    val sessionId: String,
    val name: String,
    val sizeBytes: Long,
    val status: AttachmentDownloadStatus
)
