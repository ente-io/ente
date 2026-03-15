package io.ente.photos.screensaver.ente

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import io.ente.photos.screensaver.prefs.ssaverDataStore
import kotlinx.coroutines.flow.first

class EntePublicAlbumConfigRepository(
    private val appContext: Context,
) {

    private val secureStore = EnteSecureStore(appContext)

    private object Keys {
        val legacyPublicUrl = stringPreferencesKey("pref_ente_public_url")
        val legacyAccessToken = stringPreferencesKey("pref_ente_access_token")
        val legacyCollectionKeyB64 = stringPreferencesKey("pref_ente_collection_key_b64")
        val legacyAccessTokenJWT = stringPreferencesKey("pref_ente_access_token_jwt")
        val albumName = stringPreferencesKey("pref_ente_album_name")
    }

    suspend fun get(): EntePublicAlbumConfig? {
        val prefs = appContext.ssaverDataStore.data.first()
        val albumName = prefs[Keys.albumName]

        val secureSecrets = runCatching { secureStore.getAlbumSecrets() }.getOrNull()
        if (secureSecrets != null) {
            if (hasLegacySecrets(prefs)) {
                clearLegacySecrets()
            }
            return EntePublicAlbumConfig(
                publicUrl = secureSecrets.publicUrl,
                accessToken = secureSecrets.accessToken,
                collectionKeyB64 = secureSecrets.collectionKeyB64,
                accessTokenJWT = secureSecrets.accessTokenJWT,
                albumName = albumName,
            )
        }

        val publicUrl = prefs[Keys.legacyPublicUrl].orEmpty()
        val accessToken = prefs[Keys.legacyAccessToken].orEmpty()
        val collectionKeyB64 = prefs[Keys.legacyCollectionKeyB64].orEmpty()
        val accessTokenJWT = prefs[Keys.legacyAccessTokenJWT]
        if (publicUrl.isBlank() || accessToken.isBlank() || collectionKeyB64.isBlank()) {
            return null
        }

        val migrated = runCatching {
            secureStore.saveAlbumSecrets(
                EnteSecureStore.AlbumSecrets(
                    publicUrl = publicUrl,
                    accessToken = accessToken,
                    collectionKeyB64 = collectionKeyB64,
                    accessTokenJWT = accessTokenJWT,
                ),
            )
        }.isSuccess
        if (migrated) {
            clearLegacySecrets()
        }

        return EntePublicAlbumConfig(
            publicUrl = publicUrl,
            accessToken = accessToken,
            collectionKeyB64 = collectionKeyB64,
            accessTokenJWT = accessTokenJWT,
            albumName = albumName,
        )
    }

    suspend fun setFromPublicUrl(publicUrl: String): EntePublicAlbumUrlParser.ParseResult {
        return when (val parsed = EntePublicAlbumUrlParser.parsePublicUrl(publicUrl)) {
            is EntePublicAlbumUrlParser.ParseResult.Error -> parsed
            is EntePublicAlbumUrlParser.ParseResult.Success -> {
                save(parsed.config)
                parsed
            }
        }
    }

    suspend fun save(config: EntePublicAlbumConfig) {
        secureStore.saveAlbumSecrets(
            EnteSecureStore.AlbumSecrets(
                publicUrl = config.publicUrl,
                accessToken = config.accessToken,
                collectionKeyB64 = config.collectionKeyB64,
                accessTokenJWT = config.accessTokenJWT,
            ),
        )
        appContext.ssaverDataStore.edit { prefs ->
            prefs.remove(Keys.legacyPublicUrl)
            prefs.remove(Keys.legacyAccessToken)
            prefs.remove(Keys.legacyCollectionKeyB64)
            prefs.remove(Keys.legacyAccessTokenJWT)
            val albumName = config.albumName
            if (albumName.isNullOrBlank()) {
                prefs.remove(Keys.albumName)
            } else {
                prefs[Keys.albumName] = albumName
            }
        }
    }

    suspend fun clear() {
        secureStore.clearAlbumSecrets()
        appContext.ssaverDataStore.edit { prefs ->
            prefs.remove(Keys.legacyPublicUrl)
            prefs.remove(Keys.legacyAccessToken)
            prefs.remove(Keys.legacyCollectionKeyB64)
            prefs.remove(Keys.legacyAccessTokenJWT)
            prefs.remove(Keys.albumName)
        }
    }

    private suspend fun clearLegacySecrets() {
        appContext.ssaverDataStore.edit { prefs ->
            prefs.remove(Keys.legacyPublicUrl)
            prefs.remove(Keys.legacyAccessToken)
            prefs.remove(Keys.legacyCollectionKeyB64)
            prefs.remove(Keys.legacyAccessTokenJWT)
        }
    }

    private fun hasLegacySecrets(prefs: Preferences): Boolean {
        return !prefs[Keys.legacyPublicUrl].isNullOrBlank() ||
            !prefs[Keys.legacyAccessToken].isNullOrBlank() ||
            !prefs[Keys.legacyCollectionKeyB64].isNullOrBlank() ||
            !prefs[Keys.legacyAccessTokenJWT].isNullOrBlank()
    }
}
