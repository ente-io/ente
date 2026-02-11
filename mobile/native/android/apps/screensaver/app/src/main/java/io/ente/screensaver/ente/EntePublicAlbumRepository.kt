package io.ente.screensaver.ente

import android.content.Context
import android.net.Uri
import io.ente.screensaver.diagnostics.AppLog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

class EntePublicAlbumRepository private constructor(
    private val appContext: Context,
) {

    companion object {
        @Volatile
        private var instance: EntePublicAlbumRepository? = null

        fun get(context: Context): EntePublicAlbumRepository {
            return instance ?: synchronized(this) {
                instance ?: EntePublicAlbumRepository(context.applicationContext).also { instance = it }
            }
        }

        private const val DEFAULT_REFRESH_INTERVAL_MS = 60 * 60 * 1000L
        private const val FILE_TYPE_IMAGE = 0
        private const val FILE_TYPE_VIDEO = 1
        private const val FILE_TYPE_LIVE_PHOTO = 2
    }

    private val mutex = Mutex()

    private val configRepo = EntePublicAlbumConfigRepository(appContext)
    private val storage = EntePublicAlbumCacheStorage(appContext)
    private val api = EntePublicAlbumApi(appContext)

    private var cachedState: EntePublicAlbumCacheStorage.CacheState? = null
    private var lastSyncAttemptAtMs: Long = 0

    suspend fun getConfig(): EntePublicAlbumConfig? = configRepo.get()

    suspend fun setConfigFromUrl(
        publicUrl: String,
        password: String? = null,
    ): EntePublicAlbumUrlParser.ParseResult {
        val existing = configRepo.get()
        val parsed = EntePublicAlbumUrlParser.parsePublicUrl(publicUrl)
        if (parsed is EntePublicAlbumUrlParser.ParseResult.Error) {
            AppLog.error("Ente", "Invalid public album URL: ${parsed.debugMessage()}")
            return parsed
        }

        val baseConfig = (parsed as EntePublicAlbumUrlParser.ParseResult.Success).config
        AppLog.info("Ente", "Parsed public album URL")
        val existingJwt = existing
            ?.takeIf { it.accessToken == baseConfig.accessToken }
            ?.accessTokenJWT

        AppLog.info("Ente", "Fetching album info")
        val collectionInfo = try {
            api.getCollectionInfo(
                EntePublicAlbumApi.Credentials(
                    accessToken = baseConfig.accessToken,
                ),
            )
        } catch (e: Exception) {
            AppLog.error("Ente", "Failed to fetch album info", e)
            return EntePublicAlbumUrlParser.ParseResult.Error(
                code = EntePublicAlbumUrlParser.ParseResult.Error.Code.FETCH_ALBUM_INFO_FAILED,
                detail = e.message,
            )
        }

        val trimmedPassword = password?.trim().orEmpty()
        val accessTokenJWT = if (collectionInfo.passwordEnabled) {
            when {
                trimmedPassword.isNotBlank() -> {
                    val nonce = collectionInfo.nonce
                    val opsLimit = collectionInfo.opsLimit
                    val memLimit = collectionInfo.memLimit

                    if (nonce.isNullOrBlank() || opsLimit == null || memLimit == null) {
                        AppLog.error("Ente", "Missing password parameters for album")
                        return EntePublicAlbumUrlParser.ParseResult.Error(
                            code = EntePublicAlbumUrlParser.ParseResult.Error.Code.MISSING_PASSWORD_PARAMETERS,
                        )
                    }

                    val passHash = try {
                        EnteCrypto.deriveKey(trimmedPassword, nonce, opsLimit, memLimit)
                    } catch (e: Exception) {
                        AppLog.error("Ente", "Failed to derive password hash", e)
                        return EntePublicAlbumUrlParser.ParseResult.Error(
                            code = EntePublicAlbumUrlParser.ParseResult.Error.Code.PASSWORD_HASH_DERIVATION_FAILED,
                            detail = e.message,
                        )
                    }

                    AppLog.info("Ente", "Verifying album password")
                    val jwt = try {
                        api.verifyPassword(
                            EntePublicAlbumApi.Credentials(baseConfig.accessToken),
                            passHash,
                        )
                    } catch (e: Exception) {
                        val message = e.message.orEmpty()
                        val isIncorrectPassword = message.contains("HTTP 401")
                        val code = if (isIncorrectPassword) {
                            EntePublicAlbumUrlParser.ParseResult.Error.Code.INCORRECT_PASSWORD
                        } else {
                            EntePublicAlbumUrlParser.ParseResult.Error.Code.PASSWORD_VERIFICATION_FAILED
                        }
                        val detail = if (isIncorrectPassword) null else message
                        AppLog.error("Ente", "Password verification failed: ${code.name}${detail?.let { ": $it" }.orEmpty()}", e)
                        return EntePublicAlbumUrlParser.ParseResult.Error(code = code, detail = detail)
                    }
                    AppLog.info("Ente", "Password verified")
                    jwt
                }

                !existingJwt.isNullOrBlank() -> {
                    AppLog.info("Ente", "Using saved password token")
                    existingJwt
                }

                else -> {
                    AppLog.error("Ente", "Password required for this album")
                    return EntePublicAlbumUrlParser.ParseResult.Error(
                        code = EntePublicAlbumUrlParser.ParseResult.Error.Code.PASSWORD_REQUIRED,
                    )
                }
            }
        } else {
            null
        }

        val updatedConfig = baseConfig.copy(accessTokenJWT = accessTokenJWT)

        if (existing != null && (existing.accessToken != updatedConfig.accessToken ||
                existing.collectionKeyB64 != updatedConfig.collectionKeyB64)
        ) {
            mutex.withLock {
                cachedState = null
                withContext(Dispatchers.IO) { storage.clear() }
            }
        }

        configRepo.save(updatedConfig)
        AppLog.info("Ente", "Album configured successfully")
        return EntePublicAlbumUrlParser.ParseResult.Success(updatedConfig)
    }

    suspend fun clearConfig() {
        mutex.withLock {
            cachedState = null
            withContext(Dispatchers.IO) { storage.clear() }
        }
        configRepo.clear()
        AppLog.info("Ente", "Album configuration cleared")
    }

    suspend fun clearCache() {
        val config = configRepo.get() ?: return
        mutex.withLock {
            cachedState = null
            withContext(Dispatchers.IO) {
                storage.clear()
                EnteImageCache(appContext).clear(config.accessToken)
            }
        }
        AppLog.info("Ente", "Album cache cleared")
    }

    suspend fun refreshIfNeeded(
        force: Boolean,
        refreshIntervalMs: Long = DEFAULT_REFRESH_INTERVAL_MS,
    ): EntePublicAlbumCacheStorage.CacheState? {
        val config = configRepo.get() ?: return null

        return mutex.withLock {
            val hadInMemoryState = cachedState != null
            val existing = cachedState ?: withContext(Dispatchers.IO) { storage.load(config.accessToken) }
                ?: EntePublicAlbumCacheStorage.CacheState(
                    accessToken = config.accessToken,
                    lastSyncTime = 0,
                    files = emptyMap(),
                )

            cachedState = existing

            val now = System.currentTimeMillis()

            if (!force && !hadInMemoryState && existing.files.isNotEmpty()) {
                lastSyncAttemptAtMs = now
                AppLog.info("Ente", "Using cached album snapshot for fast startup (${existing.files.size} files)")
                return@withLock existing
            }

            val needsInitialSync = existing.lastSyncTime == 0L && existing.files.isEmpty()
            val intervalAllowsRefresh = refreshIntervalMs > 0 && (now - lastSyncAttemptAtMs) > refreshIntervalMs
            val shouldRefresh = force || needsInitialSync || intervalAllowsRefresh
            if (!shouldRefresh) {
                return@withLock existing
            }

            AppLog.info("Ente", "Refreshing album (force=$force)")
            lastSyncAttemptAtMs = now

            val updatedResult = runCatching { syncLocked(config, existing) }
            updatedResult.exceptionOrNull()?.let { e ->
                AppLog.error("Ente", "Album refresh failed", e)
            }
            val updated = updatedResult.getOrNull() ?: existing
            if (updatedResult.isSuccess) {
                AppLog.info("Ente", "Album refresh complete: ${updated.files.size} files")
            }

            cachedState = updated
            withContext(Dispatchers.IO) { storage.save(updated) }
            updated
        }
    }

    suspend fun listPhotoUris(
        maxItems: Int = 5000,
        forceRefresh: Boolean = false,
        refreshIntervalMs: Long = DEFAULT_REFRESH_INTERVAL_MS,
    ): List<Uri> {
        val config = configRepo.get() ?: return emptyList()
        val state = refreshIfNeeded(force = forceRefresh, refreshIntervalMs = refreshIntervalMs) ?: return emptyList()
        if (state.files.isEmpty()) return emptyList()

        val limit = if (maxItems <= 0) Int.MAX_VALUE else maxItems
        val ids = state.files.keys.asSequence().sorted().toList()
        val updatedFiles = LinkedHashMap(state.files)
        var updated = false

        val uris = ArrayList<Uri>(minOf(limit, state.files.size))
        for (id in ids) {
            val record = updatedFiles[id] ?: continue
            if (record.fileType == -1) {
                continue
            }
            if (record.fileDecryptionHeader.isBlank()) {
                AppLog.error("Ente", "Missing file header for file $id")
                updatedFiles[id] = record.copy(fileType = -1)
                updated = true
                continue
            }

            // Fast path: use cached file type if available
            val resolvedType = if (record.fileType != null) {
                record.fileType
            } else {
                // Slow path: resolve and cache the type (should be rare after pre-resolution)
                val type = resolveFileType(record, config.collectionKeyB64)
                if (type != null) {
                    updatedFiles[id] = record.copy(fileType = type)
                    updated = true
                }
                type
            }

            // Skip non-images (videos, live photos)
            if (resolvedType != null && resolvedType != FILE_TYPE_IMAGE) {
                continue
            }

            uris.add(Uri.parse("ente://${state.accessToken}/image/$id"))
            if (uris.size >= limit) break
        }

        if (updated) {
            mutex.withLock {
                val updatedState = state.copy(files = updatedFiles)
                cachedState = updatedState
                withContext(Dispatchers.IO) { storage.save(updatedState) }
            }
        }

        if (uris.isEmpty() && updatedFiles.isNotEmpty()) {
            AppLog.error("Ente", "All files were filtered out (unsupported/decrypt failures?)")
        }

        return uris
    }

    suspend fun getFileRecord(accessToken: String, fileId: Long): EnteFileRecord? {
        val config = configRepo.get() ?: return null
        if (config.accessToken != accessToken) return null

        val state = mutex.withLock {
            cachedState ?: withContext(Dispatchers.IO) { storage.load(accessToken) }
                ?.also { cachedState = it }
        } ?: return null

        return state.files[fileId]
    }

    suspend fun getCaption(accessToken: String, fileId: Long): String? {
        val config = configRepo.get() ?: return null
        if (config.accessToken != accessToken) return null

        val state = mutex.withLock {
            cachedState ?: withContext(Dispatchers.IO) { storage.load(accessToken) }
                ?.also { cachedState = it }
        } ?: return null

        val record = state.files[fileId] ?: return null
        
        // Return cached caption if available
        if (record.caption != null) {
            return record.caption
        }

        // Decrypt and cache the caption
        val caption = resolveCaption(record, config.collectionKeyB64)
        if (caption != null) {
            record.caption = caption
        }
        
        return caption
    }

    suspend fun getCollectionKeyB64(accessToken: String): String? {
        val config = configRepo.get() ?: return null
        if (config.accessToken != accessToken) return null
        return config.collectionKeyB64
    }

    suspend fun downloadPreview(accessToken: String, fileId: Long): ByteArray {
        val config = configRepo.get() ?: run {
            AppLog.error("Ente", "Missing album config while downloading preview")
            throw IllegalStateException("Missing album config")
        }
        if (config.accessToken != accessToken) {
            AppLog.error("Ente", "Mismatched album access token for preview")
            throw IllegalStateException("Mismatched album access token")
        }
        return api.downloadPreview(credentials(config), fileId)
    }

    suspend fun downloadFile(accessToken: String, fileId: Long): ByteArray {
        val config = configRepo.get() ?: run {
            AppLog.error("Ente", "Missing album config while downloading file")
            throw IllegalStateException("Missing album config")
        }
        if (config.accessToken != accessToken) {
            AppLog.error("Ente", "Mismatched album access token for file")
            throw IllegalStateException("Mismatched album access token")
        }
        return api.downloadFile(credentials(config), fileId)
    }

    private fun credentials(config: EntePublicAlbumConfig): EntePublicAlbumApi.Credentials {
        return EntePublicAlbumApi.Credentials(
            accessToken = config.accessToken,
            accessTokenJWT = config.accessTokenJWT,
        )
    }

    private fun resolveFileType(record: EnteFileRecord, collectionKeyB64: String): Int? {
        record.fileType?.let { return it }
        if (record.metadataEncryptedData.isBlank() || record.metadataDecryptionHeader.isBlank()) {
            return null
        }

        return runCatching {
            val fileKey = EnteCrypto.decryptBoxKey(
                encryptedKeyB64 = record.encryptedKey,
                keyDecryptionNonceB64 = record.keyDecryptionNonce,
                collectionKeyB64 = collectionKeyB64,
            )
            EnteCrypto.decryptMetadataFileType(
                encryptedDataB64 = record.metadataEncryptedData,
                decryptionHeaderB64 = record.metadataDecryptionHeader,
                key = fileKey,
            )
        }.onFailure { e ->
            AppLog.error("Ente", "Failed to decrypt metadata for file ${record.id}", e)
        }.getOrNull()
    }

    private fun resolveCaption(record: EnteFileRecord, collectionKeyB64: String): String? {
        // Return cached caption if available
        record.caption?.let { return it }
        
        // Check if pubMagicMetadata is available
        if (record.pubMagicMetadataData.isNullOrBlank() || record.pubMagicMetadataHeader.isNullOrBlank()) {
            return null
        }

        return runCatching {
            val fileKey = EnteCrypto.decryptBoxKey(
                encryptedKeyB64 = record.encryptedKey,
                keyDecryptionNonceB64 = record.keyDecryptionNonce,
                collectionKeyB64 = collectionKeyB64,
            )
            
            val decryptedBytes = EnteCrypto.decryptBlobBytes(
                encryptedData = android.util.Base64.decode(record.pubMagicMetadataData, android.util.Base64.NO_WRAP),
                decryptionHeaderB64 = record.pubMagicMetadataHeader!!,
                key = fileKey,
            )
            
            val json = String(decryptedBytes, Charsets.UTF_8)
            val jsonObj = org.json.JSONObject(json)
            jsonObj.optString("caption")?.takeIf { it.isNotBlank() }
        }.onFailure { e ->
            AppLog.error("Ente", "Failed to decrypt caption for file ${record.id}", e)
        }.getOrNull()
    }

    suspend fun updateFileType(accessToken: String, fileId: Long, fileType: Int) {
        val config = configRepo.get() ?: return
        if (config.accessToken != accessToken) return

        mutex.withLock {
            val state = cachedState ?: withContext(Dispatchers.IO) { storage.load(accessToken) } ?: return@withLock
            val record = state.files[fileId] ?: return@withLock
            if (record.fileType == fileType) return@withLock

            val updatedFiles = LinkedHashMap(state.files)
            updatedFiles[fileId] = record.copy(fileType = fileType)
            val updatedState = state.copy(files = updatedFiles)

            cachedState = updatedState
            withContext(Dispatchers.IO) { storage.save(updatedState) }
        }
    }

    private suspend fun syncLocked(
        config: EntePublicAlbumConfig,
        existing: EntePublicAlbumCacheStorage.CacheState,
    ): EntePublicAlbumCacheStorage.CacheState {
        val files = LinkedHashMap(existing.files)
        var time = existing.lastSyncTime
        var hasMore = true

        while (hasMore) {
            val res = api.diff(credentials(config), time)
            hasMore = res.hasMore

            if (res.diff.isEmpty()) {
                if (!hasMore) break
                AppLog.error("Ente", "Album diff pagination returned an empty page; stopping refresh")
                break
            }

            var maxTime = time
            for (item in res.diff) {
                if (item.isDeleted) {
                    files.remove(item.id)
                    maxTime = maxOf(maxTime, item.updationTime)
                    continue
                }

                val existingRecord = files[item.id]
                files[item.id] = EnteFileRecord(
                    id = item.id,
                    encryptedKey = item.encryptedKey,
                    keyDecryptionNonce = item.keyDecryptionNonce,
                    thumbnailDecryptionHeader = item.thumbnailDecryptionHeader,
                    fileDecryptionHeader = item.fileDecryptionHeader,
                    metadataEncryptedData = item.metadataEncryptedData,
                    metadataDecryptionHeader = item.metadataDecryptionHeader,
                    pubMagicMetadataData = item.pubMagicMetadataData,
                    pubMagicMetadataHeader = item.pubMagicMetadataHeader,
                    pubMagicMetadataVersion = item.pubMagicMetadataVersion,
                    updationTime = item.updationTime,
                    fileType = existingRecord?.fileType,
                )
                maxTime = maxOf(maxTime, item.updationTime)
            }

            if (maxTime == time && hasMore) {
                AppLog.error("Ente", "Album diff pagination did not advance (sinceTime=$time); stopping refresh")
                break
            }

            time = maxTime
        }

        // Pre-resolve file types during sync for faster subsequent loads
        AppLog.info("Ente", "Pre-resolving file types for ${files.size} files")
        var resolvedCount = 0
        for ((id, record) in files) {
            if (record.fileType == null) {
                val resolvedType = resolveFileType(record, config.collectionKeyB64)
                if (resolvedType != null) {
                    files[id] = record.copy(fileType = resolvedType)
                    resolvedCount++
                }
            }
        }
        if (resolvedCount > 0) {
            AppLog.info("Ente", "Pre-resolved $resolvedCount file types during sync")
        }

        return EntePublicAlbumCacheStorage.CacheState(
            accessToken = config.accessToken,
            lastSyncTime = time,
            files = files,
        )
    }
}
