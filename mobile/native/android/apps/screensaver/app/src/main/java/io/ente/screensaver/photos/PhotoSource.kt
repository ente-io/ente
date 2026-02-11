package io.ente.screensaver.photos

import android.net.Uri

interface PhotoSource {
    suspend fun loadPhotos(maxItems: Int = 500, forceRefresh: Boolean = false): List<Uri>
}
