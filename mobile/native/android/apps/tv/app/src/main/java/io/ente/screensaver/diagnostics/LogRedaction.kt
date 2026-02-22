package io.ente.photos.screensaver.diagnostics

import android.net.Uri

fun Uri.redactedForLog(): String {
    return when (scheme) {
        "ente" -> {
            val path = encodedPath.orEmpty()
            "ente://***$path"
        }

        "http", "https" -> {
            val hostPart = host?.let { "//$it" }.orEmpty()
            val path = encodedPath.orEmpty()
            val hasQuery = !encodedQuery.isNullOrBlank()
            val hasFragment = !fragment.isNullOrBlank()
            buildString {
                append(scheme)
                append(":")
                append(hostPart)
                append(path)
                if (hasQuery) append("?…")
                if (hasFragment) append("#…")
            }
        }

        else -> toString()
    }
}
