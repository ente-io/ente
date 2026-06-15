package io.ente.photos_tv

import kotlinx.serialization.json.Json

internal object JsonConfig {
    val value = Json {
        ignoreUnknownKeys = true
    }
}
