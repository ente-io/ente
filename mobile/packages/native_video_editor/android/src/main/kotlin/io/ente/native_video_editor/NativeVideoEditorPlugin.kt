package io.ente.native_video_editor

import android.media.*
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import java.io.FileDescriptor
import java.io.FileInputStream
import java.io.IOException
import java.nio.ByteBuffer

class NativeVideoEditorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var currentJob: Job? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_video_editor")
        channel.setMethodCallHandler(this)
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
                        val editResult = trimVideoWithoutReencoding(
                            inputPath,
                            outputPath,
                            startTimeMs * 1000, // Convert to microseconds
                            endTimeMs * 1000
                        )
                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "outputPath" to outputPath,
                                    "isReEncoded" to false
                                )
                            )
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("TRIM_ERROR", e.message, null)
                        }
                    }
                }
            }

            "rotateVideo" -> {
                val inputPath = call.argument<String>("inputPath")!!
                val outputPath = call.argument<String>("outputPath")!!
                val degrees = call.argument<Int>("degrees")!!

                currentJob = scope.launch {
                    try {
                        val isReEncoded = rotateVideoWithMetadata(inputPath, outputPath, degrees)
                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "outputPath" to outputPath,
                                    "isReEncoded" to isReEncoded
                                )
                            )
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("ROTATE_ERROR", e.message, null)
                        }
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
                        // Cropping typically requires re-encoding
                        cropVideoWithReencoding(inputPath, outputPath, x, y, width, height)
                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "outputPath" to outputPath,
                                    "isReEncoded" to true
                                )
                            )
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("CROP_ERROR", e.message, null)
                        }
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

    private fun trimVideoWithoutReencoding(
        inputPath: String,
        outputPath: String,
        startTimeUs: Long,
        endTimeUs: Long
    ) {
        val extractor = MediaExtractor()
        val muxer: MediaMuxer
        var trackIndex = -1
        var videoTrackIndex = -1
        var audioTrackIndex = -1

        try {
            // Setup extractor
            extractor.setDataSource(inputPath)
            val trackCount = extractor.trackCount

            // Setup muxer
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Find and add tracks
            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

                when {
                    mime.startsWith("video/") -> {
                        videoTrackIndex = muxer.addTrack(format)
                        extractor.selectTrack(i)
                    }
                    mime.startsWith("audio/") -> {
                        audioTrackIndex = muxer.addTrack(format)
                    }
                }
            }

            muxer.start()

            // Process video track
            if (videoTrackIndex >= 0) {
                extractAndMuxTrack(
                    extractor,
                    muxer,
                    videoTrackIndex,
                    startTimeUs,
                    endTimeUs,
                    true
                )
            }

            // Process audio track
            if (audioTrackIndex >= 0) {
                // Reset extractor for audio
                extractor.unselectTrack(extractor.sampleTrackIndex)
                for (i in 0 until trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                    if (mime.startsWith("audio/")) {
                        extractor.selectTrack(i)
                        break
                    }
                }

                extractAndMuxTrack(
                    extractor,
                    muxer,
                    audioTrackIndex,
                    startTimeUs,
                    endTimeUs,
                    false
                )
            }

            muxer.stop()
        } finally {
            extractor.release()
        }
    }

    private fun extractAndMuxTrack(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        trackIndex: Int,
        startTimeUs: Long,
        endTimeUs: Long,
        isVideo: Boolean
    ) {
        extractor.seekTo(startTimeUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

        val bufferInfo = MediaCodec.BufferInfo()
        val maxBufferSize = 1024 * 1024 // 1MB buffer
        val buffer = ByteBuffer.allocate(maxBufferSize)

        var firstSampleTime = -1L

        while (true) {
            val sampleSize = extractor.readSampleData(buffer, 0)
            if (sampleSize < 0) break

            val sampleTime = extractor.sampleTime
            if (sampleTime > endTimeUs) break

            if (firstSampleTime == -1L) {
                firstSampleTime = sampleTime
            }

            bufferInfo.offset = 0
            bufferInfo.size = sampleSize
            bufferInfo.presentationTimeUs = sampleTime - firstSampleTime
            bufferInfo.flags = extractor.sampleFlags

            muxer.writeSampleData(trackIndex, buffer, bufferInfo)

            if (!extractor.advance()) break
        }
    }

    private fun rotateVideoWithMetadata(
        inputPath: String,
        outputPath: String,
        degrees: Int
    ): Boolean {
        // For Android, we can modify the rotation metadata without re-encoding
        val extractor = MediaExtractor()
        val muxer: MediaMuxer

        try {
            extractor.setDataSource(inputPath)
            val trackCount = extractor.trackCount

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Copy all tracks with rotation metadata updated
            val trackMapping = mutableMapOf<Int, Int>()

            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue

                // Update rotation for video track
                if (mime.startsWith("video/")) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        format.setInteger(MediaFormat.KEY_ROTATION, degrees)
                    }
                }

                val dstIndex = muxer.addTrack(format)
                trackMapping[i] = dstIndex
                extractor.selectTrack(i)
            }

            muxer.start()

            // Copy samples
            val bufferInfo = MediaCodec.BufferInfo()
            val buffer = ByteBuffer.allocate(1024 * 1024)

            for (i in 0 until trackCount) {
                extractor.selectTrack(i)
                extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

                while (true) {
                    val sampleSize = extractor.readSampleData(buffer, 0)
                    if (sampleSize < 0) break

                    bufferInfo.offset = 0
                    bufferInfo.size = sampleSize
                    bufferInfo.presentationTimeUs = extractor.sampleTime
                    bufferInfo.flags = extractor.sampleFlags

                    muxer.writeSampleData(trackMapping[i]!!, buffer, bufferInfo)

                    if (!extractor.advance()) break
                }
                extractor.unselectTrack(i)
            }

            muxer.stop()
            muxer.release()
            extractor.release()

            return false // Not re-encoded
        } catch (e: Exception) {
            throw e
        }
    }

    private fun cropVideoWithReencoding(
        inputPath: String,
        outputPath: String,
        cropX: Int,
        cropY: Int,
        cropWidth: Int,
        cropHeight: Int
    ) {
        // Cropping requires re-encoding with MediaCodec
        // This is a complex operation that requires Surface-to-Surface rendering
        // For now, we'll throw an exception indicating it needs implementation
        throw UnsupportedOperationException(
            "Video cropping with MediaCodec requires complex Surface rendering. " +
            "Consider using FFmpeg for this operation or implement Surface-based cropping."
        )
    }

    private fun getVideoInfo(videoPath: String): Map<String, Any> {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoPath)

            val duration = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )?.toLongOrNull() ?: 0L

            val width = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
            )?.toIntOrNull() ?: 0

            val height = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
            )?.toIntOrNull() ?: 0

            val rotation = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
            )?.toIntOrNull() ?: 0

            val bitrate = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_BITRATE
            )?.toLongOrNull() ?: 0L

            val frameRate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE
                )?.toFloatOrNull() ?: 0f
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
                var tempPath = inputPath
                var isReEncoded = false

                // Apply trim if specified
                val trimStartMs = call.argument<Int>("trimStartMs")
                val trimEndMs = call.argument<Int>("trimEndMs")
                if (trimStartMs != null && trimEndMs != null) {
                    val trimOutput = File.createTempFile("trim_", ".mp4").absolutePath
                    trimVideoWithoutReencoding(
                        tempPath,
                        trimOutput,
                        trimStartMs.toLong() * 1000,
                        trimEndMs.toLong() * 1000
                    )
                    if (tempPath != inputPath) File(tempPath).delete()
                    tempPath = trimOutput
                }

                // Apply rotation if specified
                val rotateDegrees = call.argument<Int>("rotateDegrees")
                if (rotateDegrees != null && rotateDegrees != 0) {
                    val rotateOutput = File.createTempFile("rotate_", ".mp4").absolutePath
                    rotateVideoWithMetadata(tempPath, rotateOutput, rotateDegrees)
                    if (tempPath != inputPath) File(tempPath).delete()
                    tempPath = rotateOutput
                }

                // Apply crop if specified (this will require re-encoding)
                val cropX = call.argument<Int>("cropX")
                val cropY = call.argument<Int>("cropY")
                val cropWidth = call.argument<Int>("cropWidth")
                val cropHeight = call.argument<Int>("cropHeight")
                if (cropX != null && cropY != null && cropWidth != null && cropHeight != null) {
                    // For now, cropping is not implemented without FFmpeg
                    throw UnsupportedOperationException("Cropping requires re-encoding")
                }

                // Move final result to output path
                if (tempPath != outputPath) {
                    File(tempPath).copyTo(File(outputPath), overwrite = true)
                    if (tempPath != inputPath) File(tempPath).delete()
                }

                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "outputPath" to outputPath,
                            "isReEncoded" to isReEncoded
                        )
                    )
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("PROCESS_ERROR", e.message, null)
                }
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }
}