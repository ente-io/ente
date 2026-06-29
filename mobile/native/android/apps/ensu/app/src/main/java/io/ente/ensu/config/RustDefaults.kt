package io.ente.ensu.config

import io.ente.ensu.bindings.configDefaults
import io.ente.ensu.bindings.uniffiEnsureInitialized

object RustDefaults {
    fun load(): ConfigDefaults {
        uniffiEnsureInitialized()
        return configDefaults()
    }
}
