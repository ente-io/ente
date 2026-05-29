package io.ente.ensu.domain.device

const val CHAT_MIN_RAM_BYTES: Long = 4_000_000_000L

sealed interface ChatDeviceCapability {
    val totalMemoryBytes: Long?

    data class Supported(
        override val totalMemoryBytes: Long?
    ) : ChatDeviceCapability

    data class UnsupportedLowMemory(
        override val totalMemoryBytes: Long,
        val requiredMemoryBytes: Long = CHAT_MIN_RAM_BYTES
    ) : ChatDeviceCapability

    object Unknown : ChatDeviceCapability {
        override val totalMemoryBytes: Long? = null
    }
}

interface DeviceCapabilityProvider {
    fun chatCapability(): ChatDeviceCapability
}

object UnknownDeviceCapabilityProvider : DeviceCapabilityProvider {
    override fun chatCapability(): ChatDeviceCapability = ChatDeviceCapability.Unknown
}

class UnsupportedDeviceMemoryException(
    val capability: ChatDeviceCapability.UnsupportedLowMemory
) : IllegalStateException("Device does not have enough RAM for local chat")

fun ChatDeviceCapability.isChatSupported(): Boolean =
    this !is ChatDeviceCapability.UnsupportedLowMemory

fun ChatDeviceCapability.requireChatSupported() {
    if (this is ChatDeviceCapability.UnsupportedLowMemory) {
        throw UnsupportedDeviceMemoryException(this)
    }
}
