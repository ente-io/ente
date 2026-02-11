package io.ente.screensaver.ente

data class EntePublicAlbumConfig(
    val publicUrl: String,
    val accessToken: String,
    val collectionKeyB64: String,
    val accessTokenJWT: String? = null,
)
