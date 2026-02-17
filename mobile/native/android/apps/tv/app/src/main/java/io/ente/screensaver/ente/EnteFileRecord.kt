package io.ente.photos.screensaver.ente

data class EnteFileRecord(
    val id: Long,
    val encryptedKey: String,
    val keyDecryptionNonce: String,
    val thumbnailDecryptionHeader: String,
    val fileDecryptionHeader: String,
    val metadataEncryptedData: String,
    val metadataDecryptionHeader: String,
    val pubMagicMetadataData: String? = null,
    val pubMagicMetadataHeader: String? = null,
    val pubMagicMetadataVersion: Int = 0,
    val updationTime: Long,
    val fileType: Int? = null,
    
    // Lazily decrypted and cached caption from pubMagicMetadata
    @Transient var caption: String? = null,
)
