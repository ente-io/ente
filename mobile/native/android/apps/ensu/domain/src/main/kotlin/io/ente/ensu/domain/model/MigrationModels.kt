package io.ente.ensu.domain.model

data class MigrationConfig(
    val batchSize: Long,
    val priority: MigrationPriority
)

enum class MigrationPriority {
    RECENT_FIRST,
    OLDEST_FIRST
}

enum class MigrationState {
    NOT_NEEDED,
    IN_PROGRESS,
    COMPLETE,
    FAILED
}

data class MigrationProgress(
    val state: MigrationState,
    val processed: Long,
    val remaining: Long,
    val total: Long
)
