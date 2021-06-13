package top.kikt.imagescanner.core.utils

import android.net.Uri
import android.provider.MediaStore

object MediaStoreUtils {

  fun getInsertUri(mediaType: Int): Uri {
    return when (mediaType) {
      MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
      MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
      MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
      else -> IDBUtils.allUri
    }
  }

  fun getDeleteUri(id: String, mediaType: Int): Uri {
    return Uri.withAppendedPath(getInsertUri(mediaType), id)
  }


  fun convertTypeToMediaType(type: Int): Int {
    return when (type) {
      1 -> MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
      2 -> MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
      3 -> MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO
      else -> 0
    }
  }


}