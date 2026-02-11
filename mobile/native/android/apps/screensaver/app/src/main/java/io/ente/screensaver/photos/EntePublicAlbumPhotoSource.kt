package io.ente.screensaver.photos

import android.content.Context
import android.net.Uri
import io.ente.screensaver.ente.EntePublicAlbumRepository

class EntePublicAlbumPhotoSource(
    private val context: Context,
) : PhotoSource {

    override suspend fun loadPhotos(maxItems: Int, forceRefresh: Boolean): List<Uri> {
        val repo = EntePublicAlbumRepository.get(context)
        val settings = io.ente.screensaver.prefs.PreferencesRepository(context).get()
        return repo.listPhotoUris(
            maxItems = if (maxItems <= 0) 5000 else maxItems,
            forceRefresh = forceRefresh,
            refreshIntervalMs = settings.enteRefreshIntervalMs,
        )
    }
}
