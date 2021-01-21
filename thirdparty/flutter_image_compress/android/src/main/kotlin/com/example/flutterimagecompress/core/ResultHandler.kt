package com.example.flutterimagecompress.core

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

abstract class ResultHandler(private var result: MethodChannel.Result?) {

  companion object {
    @JvmStatic
    private val handler = Handler(Looper.getMainLooper())

    @JvmStatic
    val threadPool: ExecutorService = Executors.newFixedThreadPool(8)
  }

  private var isReply = false

  fun reply(any: Any?) {
    if (isReply) {
      return
    }
    isReply = true
    val result = this.result
    this.result = null
    handler.post {
      result?.success(any)
    }
  }

  fun replyError(code: String, message: String? = null, obj: Any? = null) {
    if (isReply) {
      return
    }
    isReply = true
    val result = this.result
    this.result = null
    handler.post {
      result?.error(code, message, obj)
    }
  }

}