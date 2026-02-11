package io.ente.screensaver.photos

import android.content.Context
import android.net.Uri
import io.ente.screensaver.imageloading.ImageFormatClassifier
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class DebugAssetPhotoSource(
    private val context: Context,
    private val assetDir: String = "sample_photos",
) : PhotoSource {

    override suspend fun loadPhotos(maxItems: Int, forceRefresh: Boolean): List<Uri> =
        withContext(Dispatchers.IO) {
            val names = context.assets.list(assetDir)
                ?.filter { name ->
                    val lower = name.lowercase()
                    ImageFormatClassifier.supportedImageExtensions.any { ext -> lower.endsWith(ext) }
                }
                ?.sorted()
                ?: emptyList()

            names
                .take(maxItems)
                .map { name ->
                    Uri.parse("file:///android_asset/$assetDir/$name")
                }
        }
}
