package io.ente.native_video_editor

import android.content.Context
import android.media.*
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import java.nio.ByteBuffer

class NativeVideoEditorPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var progressChannel: EventChannel
    private var progressEventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var currentJob: Job? = null

    // Unified Media3 Transformer processor for all operations
    private lateinit var media3Processor: Media3TransformerProcessor

    companion object {
        private const val TAG = "NativeVideoEditorPlugin"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_video_editor")
        channel.setMethodCallHandler(this)

        progressChannel = EventChannel(flutterPluginBinding.binaryMessenger, "native_video_editor/progress")
        progressChannel.setStreamHandler(this)

        // Initialize unified Media3 processor
        media3Processor = Media3TransformerProcessor(context)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "trimVideo" -> {
                val inputPath = call.argument<String>("inputPath")!!
                val outputPath = call.argument<String>("outputPath")!!
                val startTimeMs = call.argument<Int>("startTimeMs")!!.toLong()
                val endTimeMs = call.argument<Int>("endTimeMs")!!.toLong()

                currentJob = scope.launch {
                    try {
                        // Use unified Media3 Transformer for optimized trimming
                        val processingResult = media3Processor.trimVideo(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            startTimeMs = startTimeMs,
                            endTimeMs = endTimeMs,
                            onProgress = { progress ->
                                scope.launch(Dispatchers.Main) {
                                    progressEventSink?.success(progress)
                                }
                            }
                        )

                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "outputPath" to processingResult.outputPath,
                                    "isReEncoded" to processingResult.isReEncoded,
                                    "processingTimeMs" to processingResult.processingTimeMs,
                                    "method" to processingResult.method
                                )
                            )
                        }
                    } catch (e: Exception) {
                        // Log.e(TAG, "Trim failed", e)
                        withContext(Dispatchers.Main) {
                            result.error("TRIM_ERROR", e.message, null)
                        }
                    } finally {
                        currentJob = null
                    }
                }
            }

            "rotateVideo" -> {
                val inputPath = call.argument<String>("inputPath")!!
                val outputPath = call.argument<String>("outputPath")!!
                val degrees = call.argument<Int>("degrees")!!

                currentJob = scope.launch {
                    try {
                        // Use unified Media3 Transformer for rotation with proper effects
                        val processingResult = media3Processor.rotateVideo(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            degrees = degrees,
                            onProgress = { progress ->
                                scope.launch(Dispatchers.Main) {
                                    progressEventSink?.success(progress)
                                }
                            }
                        )

                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "outputPath" to processingResult.outputPath,
                                    "isReEncoded" to processingResult.isReEncoded,
                                    "processingTimeMs" to processingResult.processingTimeMs,
                                    "method" to processingResult.method
                                )
                            )
                        }
                    } catch (e: Exception) {
                        // Log.e(TAG, "Rotation failed", e)
                        withContext(Dispatchers.Main) {
                            result.error("ROTATE_ERROR", e.message, null)
                        }
                    } finally {
                        currentJob = null
                    }
                }
            }

            "cropVideo" -> {
                val inputPath = call.argument<String>("inputPath")!!
                val outputPath = call.argument<String>("outputPath")!!
                val x = call.argument<Int>("x")!!
                val y = call.argument<Int>("y")!!
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!

                currentJob = scope.launch {
                    try {
                        // Use unified Media3 Transformer for cropping with proper effects
                        val processingResult = media3Processor.cropVideo(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            cropX = x,
                            cropY = y,
                            cropWidth = width,
                            cropHeight = height,
                            onProgress = { progress ->
                                scope.launch(Dispatchers.Main) {
                                    progressEventSink?.success(progress)
                                }
                            }
                        )

                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "outputPath" to processingResult.outputPath,
                                    "isReEncoded" to processingResult.isReEncoded,
                                    "processingTimeMs" to processingResult.processingTimeMs,
                                    "method" to processingResult.method
                                )
                            )
                        }
                    } catch (e: Exception) {
                        // Log.e(TAG, "Crop failed", e)
                        withContext(Dispatchers.Main) {
                            result.error("CROP_ERROR", e.message, null)
                        }
                    } finally {
                        currentJob = null
                    }
                }
            }

            "processVideo" -> {
                handleProcessVideo(call, result)
            }

            "getVideoInfo" -> {
                val videoPath = call.argument<String>("videoPath")!!
                currentJob = scope.launch {
                    try {
                        val info = getVideoInfo(videoPath)
                        withContext(Dispatchers.Main) {
                            result.success(info)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("INFO_ERROR", e.message, null)
                        }
                    } finally {
                        currentJob = null
                    }
                }
            }

            "cancelProcessing" -> {
                currentJob?.cancel()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun getVideoInfo(videoPath: String): Map<String, Any> {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoPath)

            val duration = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )?.toLongOrNull() ?: run {
                Log.w(TAG, "Failed to extract duration metadata from video: $videoPath")
                0L
            }

            val width = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
            )?.toIntOrNull() ?: run {
                Log.w(TAG, "Failed to extract width metadata from video: $videoPath")
                0
            }

            val height = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
            )?.toIntOrNull() ?: run {
                Log.w(TAG, "Failed to extract height metadata from video: $videoPath")
                0
            }

            val rotation = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
            )?.toIntOrNull() ?: run {
                Log.w(TAG, "Failed to extract rotation metadata from video: $videoPath")
                0
            }

            val bitrate = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_BITRATE
            )?.toLongOrNull() ?: run {
                Log.w(TAG, "Failed to extract bitrate metadata from video: $videoPath")
                0L
            }

            val frameRate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE
                )?.toFloatOrNull() ?: run {
                    Log.w(TAG, "Failed to extract frame rate metadata from video: $videoPath")
                    0f
                }
            } else {
                0f
            }

            mapOf(
                "duration" to duration,
                "width" to width,
                "height" to height,
                "rotation" to rotation,
                "bitrate" to bitrate,
                "frameRate" to frameRate
            )
        } finally {
            retriever.release()
        }
    }

    private fun handleProcessVideo(call: MethodCall, result: Result) {
        val inputPath = call.argument<String>("inputPath")!!
        val outputPath = call.argument<String>("outputPath")!!

        currentJob = scope.launch {
            try {
                // Collect all transformation parameters
                val trimStartMs = call.argument<Int>("trimStartMs")?.toLong()
                val trimEndMs = call.argument<Int>("trimEndMs")?.toLong()
                val rotateDegrees = call.argument<Int>("rotateDegrees")
                val cropX = call.argument<Int>("cropX")
                val cropY = call.argument<Int>("cropY")
                val cropWidth = call.argument<Int>("cropWidth")
                val cropHeight = call.argument<Int>("cropHeight")

                // Process all transformations in a single pass with Media3 Transformer
                val processingResult = media3Processor.processVideo(
                    inputPath = inputPath,
                    outputPath = outputPath,
                    trimStartMs = trimStartMs,
                    trimEndMs = trimEndMs,
                    rotateDegrees = rotateDegrees,
                    cropX = cropX,
                    cropY = cropY,
                    cropWidth = cropWidth,
                    cropHeight = cropHeight,
                    onProgress = { progress ->
                        scope.launch(Dispatchers.Main) {
                            progressEventSink?.success(progress)
                        }
                    }
                )

                val processingSteps = mutableListOf<String>()
                if (trimStartMs != null) processingSteps.add("Trim")
                if (rotateDegrees != null && rotateDegrees != 0) processingSteps.add("Rotate")
                if (cropX != null) processingSteps.add("Crop")

                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "outputPath" to outputPath,
                            "isReEncoded" to processingResult.isReEncoded,
                            "processingTimeMs" to processingResult.processingTimeMs,
                            "processingSteps" to processingSteps
                        )
                    )
                }
            } catch (e: Exception) {
                // Log.e(TAG, "Process video failed", e)
                withContext(Dispatchers.Main) {
                    result.error("PROCESS_ERROR", e.message, null)
                }
            } finally {
                currentJob = null
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        progressChannel.setStreamHandler(null)
        scope.cancel()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        progressEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        progressEventSink = null
    }
}
