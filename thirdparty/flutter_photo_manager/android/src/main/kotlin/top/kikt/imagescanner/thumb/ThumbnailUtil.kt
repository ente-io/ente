package top.kikt.imagescanner.thumb

import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.Priority
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.transition.Transition
import io.flutter.plugin.common.MethodChannel
import top.kikt.imagescanner.core.entity.ThumbLoadOption
import top.kikt.imagescanner.util.ResultHandler
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Created by debuggerx on 18-9-27 下午2:08
 */
object ThumbnailUtil {

  fun getThumbnailByGlide(ctx: Context, path: String, width: Int, height: Int, format: Bitmap.CompressFormat, quality: Int, result: MethodChannel.Result?) {
    val resultHandler = ResultHandler(result)

    Glide.with(ctx)
        .asBitmap()
        .load(File(path))
        .priority(Priority.IMMEDIATE)
        .into(object : BitmapTarget(width, height) {
          override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
            super.onResourceReady(resource, transition)
            val bos = ByteArrayOutputStream()

            resource.compress(format, quality, bos)
            resultHandler.reply(bos.toByteArray())
          }

          override fun onLoadCleared(placeholder: Drawable?) {
            resultHandler.reply(null)
          }

          override fun onLoadFailed(errorDrawable: Drawable?) {
            resultHandler.reply(null)
          }
        })
  }


  fun getThumbOfUri(context: Context, uri: Uri, width: Int, height: Int, format: Bitmap.CompressFormat, quality: Int, callback: (ByteArray?) -> Unit) {
    Glide.with(context)
        .asBitmap()
        .load(uri)
        .priority(Priority.IMMEDIATE)
        .into(object : BitmapTarget(width, height) {
          override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
            super.onResourceReady(resource, transition)
            val bos = ByteArrayOutputStream()

            resource.compress(format, quality, bos)
            callback(bos.toByteArray())
          }

          override fun onLoadCleared(placeholder: Drawable?) {
            callback(null)
          }
        })
  }

  fun requestCacheThumb(context: Context, uri: Uri, thumbLoadOption: ThumbLoadOption): FutureTarget<Bitmap> {
    return Glide.with(context)
        .asBitmap()
        .priority(Priority.LOW)
        .load(uri)
        .submit(thumbLoadOption.width, thumbLoadOption.height)
  }


  fun requestCacheThumb(context: Context, path: String, thumbLoadOption: ThumbLoadOption): FutureTarget<Bitmap> {
    return Glide.with(context)
        .asBitmap()
        .priority(Priority.LOW)
        .load(path)
        .submit(thumbLoadOption.width, thumbLoadOption.height)
  }

  fun clearCache(context: Context) {
    Glide.get(context).apply {
      clearDiskCache()
    }
  }


}
