package top.kikt.imagescanner.core.cache

import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.utils.AndroidQDBUtils
import top.kikt.imagescanner.util.LogUtils
import java.io.File
import java.io.FileOutputStream
import java.lang.Exception

/// create 2019-09-10 by cai

@RequiresApi(Build.VERSION_CODES.Q)
class AndroidQCache {

  fun getCacheFile(context: Context, id: String, displayName: String, isOrigin: Boolean): File {
    val originString =
        if (isOrigin) {
          "_origin"
        } else {
          ""
        }
    val name = "$id${originString}_${displayName}"
    return File(context.cacheDir, name)
  }

  fun getCacheFile(context: Context, assetId: String, extName: String, type: Int, isOrigin: Boolean): File? {
    val targetFile = getCacheFile(context, assetId, extName, isOrigin)

    if (targetFile.exists()) {
      return targetFile
    }

    val contentResolver = context.contentResolver

    var uri = AndroidQDBUtils.getUri(assetId, type, isOrigin)
    if (uri == Uri.EMPTY) {
      return null
    }
    try {
      val inputStream = contentResolver.openInputStream(uri)
      val outputStream = FileOutputStream(targetFile)
      outputStream.use {
        inputStream?.copyTo(it)
      }
    }catch (e:Exception){
      LogUtils.info("$assetId , isOrigin: $isOrigin, copy file error:${e.localizedMessage}")
      return null
    }
    return targetFile
  }

  fun saveAssetCache(context: Context, asset: AssetEntity, byteArray: ByteArray, isOrigin: Boolean = false) {
    val file = getCacheFile(context, asset.id, asset.displayName, isOrigin)
    if (file.exists()) {
      LogUtils.info("${asset.id} , isOrigin: $isOrigin, cache file exists, ignore save")
      return
    }

    if (file.parentFile?.exists() != true) {
      file.mkdirs()
    }
    file.writeBytes(byteArray)

    LogUtils.info("${asset.id} , isOrigin: $isOrigin, cached")
  }

  fun clearAllCache(context: Context) {
    val files = context.cacheDir
        ?.listFiles()
        ?.filterNotNull() ?: return
    for (file in files) {
      file.delete()
    }
  }
}