package top.kikt.imagescanner.core

import android.content.ContentResolver
import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.BaseColumns
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.core.utils.IDBUtils
import top.kikt.imagescanner.util.LogUtils

/// create 2019-09-09 by cai


class PhotoManagerNotifyChannel(val applicationContext: Context, private val messenger: BinaryMessenger, handler: Handler) {

  private var notifying = false

  private val videoObserver = MediaObserver(MEDIA_TYPE_VIDEO, handler)
  private val imageObserver = MediaObserver(MEDIA_TYPE_IMAGE, handler)
  private val audioObserver = MediaObserver(MEDIA_TYPE_AUDIO, handler)
  private val allUri = IDBUtils.allUri
  private val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
  private val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
  private val audioUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

  private val methodChannel = MethodChannel(messenger, "top.kikt/photo_manager/notify")

  private val context
    get() = applicationContext

  fun startNotify() {
    if (notifying) {
      return
    }
    registerObserver(imageObserver, imageUri)
    registerObserver(videoObserver, videoUri)
    registerObserver(audioObserver, audioUri)

    notifying = true
  }

  private fun registerObserver(mediaObserver: MediaObserver, uri: Uri) {
    context.contentResolver.registerContentObserver(uri, false, mediaObserver)
    mediaObserver.uri = uri
  }

  fun stopNotify() {
    if (!notifying) {
      return
    }
    notifying = false
    context.contentResolver.unregisterContentObserver(imageObserver)
    context.contentResolver.unregisterContentObserver(videoObserver)
    context.contentResolver.unregisterContentObserver(audioObserver)
  }

  fun onOuterChange(uri: Uri?, changeType: String, id: Long?, galleryId: Long?, observerType: Int) {
    val resultMap = hashMapOf<String, Any?>(
            "platform" to "android",
            "uri" to uri.toString(),
            "type" to changeType,
            "mediaType" to observerType
    )
    if (id != null) {
      resultMap["id"] = id
    }
    if (galleryId != null) {
      resultMap["galleryId"] = galleryId
    }

    LogUtils.debug(resultMap)

    methodChannel.invokeMethod("change", resultMap)
  }

  fun setAndroidQExperimental(open: Boolean) {
    methodChannel.invokeMethod("setAndroidQExperimental", mapOf("open" to open))
  }

  private inner class MediaObserver(val type: Int, handler: Handler = Handler(Looper.getMainLooper())) : ContentObserver(handler) {
    var uri: Uri = Uri.parse("content://${MediaStore.AUTHORITY}")

    val context: Context
      get() = applicationContext

    val cr: ContentResolver
      get() = context.contentResolver

    override fun onChange(selfChange: Boolean, uri: Uri?) {
      super.onChange(selfChange, uri)
      if (uri == null) {
        return
      }
      val last = uri.lastPathSegment
      val id = last?.toLongOrNull()

      if (id != null) { // insert or update
        val cursor = cr.query(
                allUri,
                arrayOf(DATE_ADDED, DATE_MODIFIED, MEDIA_TYPE),
                "${BaseColumns._ID} = ?",
                arrayOf(id.toString()),
                null
        )
        cursor?.use {
          // find date to know insert or update
          if (cursor.moveToNext()) {
            return
          }
          val addTimestampSecond = cursor.getLong(cursor.getColumnIndex(DATE_ADDED))
          val currentTimeMillis = System.currentTimeMillis()

          val diffTime = currentTimeMillis / 1000 - addTimestampSecond

          // Within 30s, it is considered to be inserted, if it is exceeded, it is considered to be changed

          val typeString = if (diffTime < 30) {
            "insert"
          } else {
            "update"
          }
          // get Type
          val type = cursor.getInt(cursor.getColumnIndex(MEDIA_TYPE))
          val (gId, gName) = getGalleryIdAndName(id, type)

          if (gId == null || gName == null) {
            return
          }
          onOuterChange(uri, typeString, id, gId, type)
        }
      } else { // delete

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
          if (uri == this.uri) {
            onOuterChange(uri, "insert", null, null, type)
            return
          }
        }

        onOuterChange(uri, "delete", null, null, type)
      }
    }

    private fun getGalleryIdAndName(id: Long, type: Int): Pair<Long?, String?> {
      when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
          val cursor = cr.query(
                  allUri,
                  arrayOf(MediaStore.MediaColumns.BUCKET_ID, MediaStore.MediaColumns.BUCKET_DISPLAY_NAME),
                  "${BaseColumns._ID} = ?",
                  arrayOf(id.toString()),
                  null
          )
          cursor?.use {
            if (cursor.moveToNext()) {
              val galleryId = cursor.getLong(cursor.getColumnIndex(MediaStore.MediaColumns.BUCKET_ID))
              val galleryName = cursor.getString(cursor.getColumnIndex(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME))
              return Pair(galleryId, galleryName)
            }
          }

        }
        type == MEDIA_TYPE_AUDIO -> {
          val cursor = cr.query(
                  allUri,
                  arrayOf(MediaStore.Audio.AudioColumns.ALBUM_ID, MediaStore.Audio.AudioColumns.ALBUM),
                  "${BaseColumns._ID} = ?",
                  arrayOf(id.toString()),
                  null
          )

          cursor?.use {
            if (cursor.moveToNext()) {
              val galleryId = cursor.getLong(cursor.getColumnIndex(MediaStore.Audio.AudioColumns.ALBUM_ID))
              val galleryName = cursor.getString(cursor.getColumnIndex(MediaStore.Audio.AudioColumns.ALBUM))
              return Pair(galleryId, galleryName)
            }
          }
        }
        else -> {
          val cursor = cr.query(
                  allUri,
                  arrayOf("bucket_id", "bucket_display_name"),
                  "${BaseColumns._ID} = ?",
                  arrayOf(id.toString()),
                  null
          )

          cursor?.use {
            if (cursor.moveToNext()) {
              val galleryId = cursor.getLong(cursor.getColumnIndex("bucket_id"))
              val galleryName = cursor.getString(cursor.getColumnIndex("bucket_display_name"))
              return Pair(galleryId, galleryName)
            }
          }
        }
      }

      return Pair(null, null)
    }
  }


}

