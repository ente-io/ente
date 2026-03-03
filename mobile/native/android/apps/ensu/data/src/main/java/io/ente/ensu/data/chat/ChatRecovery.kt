package io.ente.ensu.data.chat

internal object ChatRecovery {
    private val resetSignals = listOf(
        "stream pull failed",
        "invalid blob",
        "invalid encrypted"
    )

    fun shouldResetFromMessage(message: String): Boolean {
        val lower = message.lowercase()
        return resetSignals.any { lower.contains(it) }
    }
}
