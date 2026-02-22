package io.ente.photos.screensaver.photos

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import io.ente.photos.screensaver.imageloading.ImageFormatClassifier
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class MediaStorePhotoSource(
    private val context: Context,
) : PhotoSource {

    override suspend fun loadPhotos(maxItems: Int, forceRefresh: Boolean): List<Uri> =
        withContext(Dispatchers.IO) {
            val limit = if (maxItems <= 0) Int.MAX_VALUE else maxItems
            val photos = ArrayList<Uri>(limit.coerceAtMost(5000))

            val filesUri = MediaStore.Files.getContentUri("external")
            val projection = arrayOf(
                MediaStore.Files.FileColumns._ID,
            )

            val extensionClauses = ImageFormatClassifier.supportedImageExtensions.joinToString(" OR ") {
                "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ?"
            }
            val selection = buildString {
                append("(")
                append("${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?")
                append(" OR ")
                append("${MediaStore.Files.FileColumns.MIME_TYPE} LIKE ?")
                if (extensionClauses.isNotBlank()) {
                    append(" OR ")
                    append("(")
                    append(extensionClauses)
                    append(")")
                }
                append(")")
            }
            val selectionArgs = buildList {
                add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
                add("image/%")
                ImageFormatClassifier.supportedImageExtensions.forEach { ext -> add("%$ext") }
            }.toTypedArray()

            val sortOrder = "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"

            try {
                context.contentResolver.query(filesUri, projection, selection, selectionArgs, sortOrder)
                    ?.use { cursor ->
                        val idCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                        while (cursor.moveToNext() && photos.size < limit) {
                            val id = cursor.getLong(idCol)
                            photos.add(ContentUris.withAppendedId(filesUri, id))
                        }
                    }
            } catch (_: SecurityException) {
                return@withContext emptyList()
            }

            photos
        }
}
