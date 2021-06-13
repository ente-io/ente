package top.kikt.imagescanner.core.utils

import android.graphics.BitmapFactory
import android.media.MediaPlayer
import android.util.SizeF

object VideoUtils {

  data class VideoInfo(var width: Int?, var height: Int?, var duration: Int?)

  fun getPropertiesUseMediaPlayer(path: String): VideoInfo {
    val mediaPlayer = MediaPlayer()
    mediaPlayer.setDataSource(path)
    mediaPlayer.setOnErrorListener { mp, what, extra ->
      true
    }
    try {
      mediaPlayer.prepare()
    } catch (e: Throwable) {
      mediaPlayer.release()
      return VideoInfo(null, null, null)
    }
    mediaPlayer.videoHeight
    val info = VideoInfo(mediaPlayer.videoWidth, mediaPlayer.videoHeight, mediaPlayer.duration)

    mediaPlayer.stop()
    mediaPlayer.release()

    return info
  }

}