package top.kikt.imagescanner.core

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.core.utils.IDBUtils
import top.kikt.imagescanner.util.ResultHandler

class PhotoManagerDeleteManager(val context: Context, var activity: Activity?) : PluginRegistry.ActivityResultListener {

  fun bindActivity(activity: Activity?) {
    this.activity = activity
  }

  private var requestCodeIndex = 3000
  private var androidRDeleteRequestCode = 40069

  private val uriMap = HashMap<Int, Uri>()

  private val cr: ContentResolver
    get() = context.contentResolver

  private fun isHandleCode(requestCode: Int): Boolean {
    return uriMap.containsKey(requestCode)
  }

  private fun addRequestUri(uri: Uri): Int {
    val requestCode = requestCodeIndex
    requestCodeIndex++
    uriMap[requestCode] = uri
    return requestCode
  }

  private val androidQResult = arrayListOf<String>()

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == androidRDeleteRequestCode) {
      handleAndroidRDelete(resultCode, data)
      return true
    }
    if (!isHandleCode(requestCode)) {
      return false;
    }

    val uri = uriMap.remove(requestCode) ?: return true
    if (resultCode == Activity.RESULT_OK) {
      // User allow delete asset.
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
        deleteWithUriInApi29(uri, true)
        uri.lastPathSegment?.let {
          androidQResult.add(it)
        }
      }
    }

    if (uriMap.isEmpty()) {
      androidQHandler?.reply(androidQResult)
      androidQResult.clear()
      androidQHandler = null
    }

    return true
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  fun deleteWithUriInApi29(uri: Uri, havePermission: Boolean) {
    try {
      cr.delete(uri, null, null)
    } catch (e: Exception) {
      if (e is RecoverableSecurityException) {
        if (activity == null) {
          return
        }
        if (havePermission) {
          return
        }
        val requestCode = addRequestUri(uri)
        activity?.startIntentSenderForResult(
            e.userAction.actionIntent.intentSender,
            requestCode,
            null,
            0,
            0,
            0
        )
      }
    }
  }

  private fun handleAndroidRDelete(resultCode: Int, data: Intent?) {
    if (resultCode == Activity.RESULT_OK) {
      androidRHandler?.apply {
        val ids = call?.argument<List<String>>("ids") ?: return@apply
        androidRHandler?.reply(ids)
      }
    } else {
      androidRHandler?.reply(listOf<String>())
    }
  }

  fun deleteInApi28(ids: List<String>) {
    val where = ids.joinToString(",") { "?" }
    cr.delete(IDBUtils.allUri, "${MediaStore.MediaColumns._ID} in ($where)", ids.toTypedArray())
  }

  private var androidRHandler: ResultHandler? = null

  @RequiresApi(Build.VERSION_CODES.R)
  fun deleteInApi30(uris: List<Uri?>, resultHandler: ResultHandler) {
    this.androidRHandler = resultHandler
    val pendingIntent = MediaStore.createTrashRequest(cr, uris.mapNotNull { it }, true)
    activity?.startIntentSenderForResult(pendingIntent.intentSender, androidRDeleteRequestCode, null, 0, 0, 0)
  }

  private var androidQHandler: ResultHandler? = null

  @RequiresApi(Build.VERSION_CODES.Q)
  fun deleteWithUriInApi29(ids: List<String>, uris: List<Uri>, resultHandler: ResultHandler, havePermission: Boolean) {
    if (Environment.isExternalStorageLegacy()) {
      deleteInApi28(ids)
      resultHandler.reply(ids)
      return
    }

    androidQHandler = resultHandler
    androidQResult.clear()
    for (uri in uris) {
      deleteWithUriInApi29(uri, havePermission)
    }
  }

}