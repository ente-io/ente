package io.ente.ensu.data

import android.app.ActivityManager
import android.content.Context
import io.ente.ensu.domain.device.CHAT_MIN_RAM_BYTES
import io.ente.ensu.domain.device.ChatDeviceCapability
import io.ente.ensu.domain.device.DeviceCapabilityProvider

class AndroidDeviceCapabilityProvider(context: Context) : DeviceCapabilityProvider {
    private val appContext = context.applicationContext

    override fun chatCapability(): ChatDeviceCapability {
        val activityManager = appContext.getSystemService(ActivityManager::class.java)
            ?: return ChatDeviceCapability.Unknown
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val totalMemoryBytes = memoryInfo.totalMem
        return if (totalMemoryBytes < CHAT_MIN_RAM_BYTES) {
            ChatDeviceCapability.UnsupportedLowMemory(totalMemoryBytes)
        } else {
            ChatDeviceCapability.Supported(totalMemoryBytes)
        }
    }
}
