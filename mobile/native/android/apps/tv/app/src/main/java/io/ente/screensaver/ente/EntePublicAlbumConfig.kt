package io.ente.photos.screensaver.ente

data class EntePublicAlbumConfig(
    val publicUrl: String,
    val accessToken: String,
    val collectionKeyB64: String,
    val accessTokenJWT: String? = null,
    val albumName: String? = null,
)
