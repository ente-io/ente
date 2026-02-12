package io.ente.photos.screensaver.ente

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import io.ente.photos.screensaver.prefs.ssaverDataStore
import kotlinx.coroutines.flow.first

class EntePublicAlbumConfigRepository(
    private val appContext: Context,
) {

    private object Keys {
        val publicUrl = stringPreferencesKey("pref_ente_public_url")
        val accessToken = stringPreferencesKey("pref_ente_access_token")
        val collectionKeyB64 = stringPreferencesKey("pref_ente_collection_key_b64")
        val accessTokenJWT = stringPreferencesKey("pref_ente_access_token_jwt")
    }

    suspend fun get(): EntePublicAlbumConfig? {
        val prefs = appContext.ssaverDataStore.data.first()
        val publicUrl = prefs[Keys.publicUrl].orEmpty()
        val accessToken = prefs[Keys.accessToken].orEmpty()
        val collectionKeyB64 = prefs[Keys.collectionKeyB64].orEmpty()
        val accessTokenJWT = prefs[Keys.accessTokenJWT]

        if (publicUrl.isBlank() || accessToken.isBlank() || collectionKeyB64.isBlank()) {
            return null
        }

        return EntePublicAlbumConfig(
            publicUrl = publicUrl,
            accessToken = accessToken,
            collectionKeyB64 = collectionKeyB64,
            accessTokenJWT = accessTokenJWT,
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
        appContext.ssaverDataStore.edit { prefs ->
            prefs[Keys.publicUrl] = config.publicUrl
            prefs[Keys.accessToken] = config.accessToken
            prefs[Keys.collectionKeyB64] = config.collectionKeyB64
            val jwt = config.accessTokenJWT
            if (jwt.isNullOrBlank()) {
                prefs.remove(Keys.accessTokenJWT)
            } else {
                prefs[Keys.accessTokenJWT] = jwt
            }
        }
    }

    suspend fun clear() {
        appContext.ssaverDataStore.edit { prefs ->
            prefs.remove(Keys.publicUrl)
            prefs.remove(Keys.accessToken)
            prefs.remove(Keys.collectionKeyB64)
            prefs.remove(Keys.accessTokenJWT)
        }
    }
}
