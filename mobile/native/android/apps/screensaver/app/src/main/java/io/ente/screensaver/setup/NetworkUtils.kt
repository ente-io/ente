package io.ente.photos.screensaver.setup

import java.net.Inet4Address
import java.net.NetworkInterface

object NetworkUtils {

    data class LocalAddress(
        val interfaceName: String,
        val address: String,
    )

    fun getLocalIpv4Address(): String? {
        return getLocalIpv4Addresses().firstOrNull()?.address
    }

    fun getLocalIpv4Addresses(): List<LocalAddress> {
        return runCatching {
            val addresses = NetworkInterface.getNetworkInterfaces().toList()
                .asSequence()
                .filter { it.isUp && !it.isLoopback && !it.isVirtual }
                .flatMap { iface ->
                    iface.inetAddresses.toList().asSequence()
                        .filterIsInstance<Inet4Address>()
                        .mapNotNull { addr ->
                            val ip = addr.hostAddress?.takeIf { isUsableAddress(it) }
                                ?: return@mapNotNull null
                            LocalAddress(iface.name, ip)
                        }
                }
                .distinctBy { it.address }
                .toList()

            addresses.sortedWith(
                compareBy<LocalAddress> { interfacePriority(it.interfaceName) }
                    .thenBy { it.address },
            )
        }.getOrDefault(emptyList())
    }

    private fun isUsableAddress(ip: String): Boolean {
        return ip.isNotBlank() &&
            !ip.startsWith("127.") &&
            !ip.startsWith("169.254.")
    }

    private fun interfacePriority(name: String): Int {
        val lower = name.lowercase()
        return when {
            lower.startsWith("wlan") || lower.startsWith("wifi") -> 0
            lower.startsWith("eth") || lower.startsWith("en") -> 1
            else -> 2
        }
    }
}
