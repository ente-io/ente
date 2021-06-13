package top.kikt.imagescanner.thumb

import android.graphics.Bitmap
import com.bumptech.glide.request.transition.Transition

/// create 2019-09-12 by cai


abstract class BitmapTarget(width: Int, height: Int) : CustomTarget<Bitmap>(width, height) {

    private var bitmap: Bitmap? = null

    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
        this.bitmap = resource
    }

    override fun onDestroy() {
        super.onDestroy()
        if (bitmap?.isRecycled == false) {
            bitmap?.recycle()
        }
    }

}