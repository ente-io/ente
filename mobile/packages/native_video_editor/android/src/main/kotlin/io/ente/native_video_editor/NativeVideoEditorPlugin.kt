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
                        Log.i(TAG, "Starting trim operation: $startTimeMs-$endTimeMs ms")
                        // Use unified Media3 Transformer for optimized trimming
                        val processingResult = media3Processor.trimVideo(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            startTimeMs = startTimeMs,
                            endTimeMs = endTimeMs,
                            onProgress = { progress ->
                                Log.d(TAG, "Trim progress: ${(progress * 100).toInt()}%")
                                withContext(Dispatchers.Main) {
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
                        Log.e(TAG, "Trim failed", e)
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
                        Log.i(TAG, "Starting rotation operation: $degrees degrees")
                        // Use unified Media3 Transformer for rotation with proper effects
                        val processingResult = media3Processor.rotateVideo(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            degrees = degrees,
                            onProgress = { progress ->
                                Log.d(TAG, "Rotation progress: ${(progress * 100).toInt()}%")
                                withContext(Dispatchers.Main) {
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
                        Log.e(TAG, "Rotation failed", e)
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
                        Log.i(TAG, "Starting crop operation: [$x,$y ${width}x$height]")
                        // Use unified Media3 Transformer for cropping with proper effects
                        val processingResult = media3Processor.cropVideo(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            cropX = x,
                            cropY = y,
                            cropWidth = width,
                            cropHeight = height,
                            onProgress = { progress ->
                                Log.d(TAG, "Crop progress: ${(progress * 100).toInt()}%")
                                withContext(Dispatchers.Main) {
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
                        Log.e(TAG, "Crop failed", e)
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

    private fun rotateVideoWithSimpleCopy(
        inputPath: String,
        outputPath: String,
        degrees: Int
    ): Boolean {
        // WARNING: This only modifies metadata, not the actual video frames
        // Some video players may ignore rotation metadata
        // For guaranteed rotation, use re-encoding (but that's slower)
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
                    // Get existing rotation if any
                    val existingRotation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                                              format.containsKey(MediaFormat.KEY_ROTATION)) {
                        format.getInteger(MediaFormat.KEY_ROTATION)
                    } else {
                        0
                    }

                    // Apply new rotation on top of existing rotation
                    val totalRotation = (existingRotation + degrees) % 360

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        format.setInteger(MediaFormat.KEY_ROTATION, totalRotation)
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

    /* Broken implementation - causes artifacts, needs proper OpenGL or transform implementation
    private fun rotateVideoWithReencoding(
        inputPath: String,
        outputPath: String,
        degrees: Int
    ) {*/
    private fun rotateVideoWithReencodingDisabled(
        inputPath: String,
        outputPath: String,
        degrees: Int
    ) {
        val extractor = MediaExtractor()
        val muxer: MediaMuxer

        try {
            extractor.setDataSource(inputPath)
            val trackCount = extractor.trackCount

            var videoTrackIndex = -1
            var audioTrackIndex = -1
            var videoFormat: MediaFormat? = null
            var audioFormat: MediaFormat? = null

            // Find video and audio tracks
            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME)

                if (mime?.startsWith("video/") == true && videoTrackIndex == -1) {
                    videoTrackIndex = i
                    videoFormat = format
                } else if (mime?.startsWith("audio/") == true && audioTrackIndex == -1) {
                    audioTrackIndex = i
                    audioFormat = format
                }
            }

            if (videoFormat == null) {
                throw IllegalArgumentException("No video track found")
            }

            // Get original dimensions
            val originalWidth = videoFormat.getInteger(MediaFormat.KEY_WIDTH)
            val originalHeight = videoFormat.getInteger(MediaFormat.KEY_HEIGHT)

            // Calculate rotated dimensions
            val (outputWidth, outputHeight) = when (degrees) {
                90, 270 -> originalHeight to originalWidth
                else -> originalWidth to originalHeight
            }

            // Setup decoder
            val decoder = MediaCodec.createDecoderByType(videoFormat.getString(MediaFormat.KEY_MIME)!!)

            // Setup encoder with rotated dimensions and original frame rate
            val outputFormat = MediaFormat.createVideoFormat("video/avc", outputWidth, outputHeight).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)

                // Safely get bit rate with fallback
                val originalBitRate = if (videoFormat.containsKey(MediaFormat.KEY_BIT_RATE)) {
                    try {
                        videoFormat.getInteger(MediaFormat.KEY_BIT_RATE)
                    } catch (e: Exception) {
                        1000000 // 1Mbps fallback
                    }
                } else {
                    1000000 // 1Mbps fallback
                }
                setInteger(MediaFormat.KEY_BIT_RATE, originalBitRate)

                // Safely get frame rate with fallback
                val originalFrameRate = if (videoFormat.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                    try {
                        videoFormat.getInteger(MediaFormat.KEY_FRAME_RATE)
                    } catch (e: Exception) {
                        30 // fallback
                    }
                } else {
                    30 // fallback
                }
                setInteger(MediaFormat.KEY_FRAME_RATE, originalFrameRate)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            }

            val encoder = MediaCodec.createEncoderByType("video/avc")
            encoder.configure(outputFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            val encoderSurface = encoder.createInputSurface()
            encoder.start()

            decoder.configure(videoFormat, encoderSurface, null, 0)
            decoder.start()

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            // Process video frames with rotation
            processRotatedVideo(extractor, decoder, encoder, muxer, videoTrackIndex, audioTrackIndex, audioFormat, degrees, inputPath)

            // Cleanup
            decoder.stop()
            decoder.release()
            encoder.stop()
            encoder.release()
            muxer.stop()
            muxer.release()
            extractor.release()
            encoderSurface.release()

        } catch (e: Exception) {
            throw e
        }
    }

    private fun processRotatedVideo(
        extractor: MediaExtractor,
        decoder: MediaCodec,
        encoder: MediaCodec,
        muxer: MediaMuxer,
        videoTrackIndex: Int,
        audioTrackIndex: Int,
        audioFormat: MediaFormat?,
        degrees: Int,
        inputPath: String
    ) {
        extractor.selectTrack(videoTrackIndex)

        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false
        var muxerStarted = false
        var muxerTrackIndex = -1

        val timeoutUs = 10000L

        while (!outputDone) {
            // Feed input to decoder
            if (!inputDone) {
                val inputBufferIndex = decoder.dequeueInputBuffer(timeoutUs)
                if (inputBufferIndex >= 0) {
                    val inputBuffer = decoder.getInputBuffer(inputBufferIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)

                    if (sampleSize < 0) {
                        decoder.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        val sampleTime = extractor.sampleTime
                        decoder.queueInputBuffer(inputBufferIndex, 0, sampleSize, sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            // Get output from decoder (renders to encoder's rotated surface)
            val decoderOutputIndex = decoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            if (decoderOutputIndex >= 0) {
                val doRender = bufferInfo.size != 0
                decoder.releaseOutputBuffer(decoderOutputIndex, doRender)

                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    encoder.signalEndOfInputStream()
                }
            }

            // Get output from encoder
            val encoderOutputIndex = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            when {
                encoderOutputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!muxerStarted) {
                        val newFormat = encoder.outputFormat
                        muxerTrackIndex = muxer.addTrack(newFormat)

                        // Add audio track BEFORE starting muxer
                        var audioMuxerTrackIndex = -1
                        if (audioTrackIndex >= 0 && audioFormat != null) {
                            audioMuxerTrackIndex = muxer.addTrack(audioFormat)
                        }

                        muxer.start()
                        muxerStarted = true

                        // Process audio track AFTER muxer is started
                        if (audioMuxerTrackIndex >= 0) {
                            val audioExtractor = MediaExtractor()
                            audioExtractor.setDataSource(inputPath)
                            audioExtractor.selectTrack(audioTrackIndex)

                            val buffer = ByteBuffer.allocate(1024 * 1024)
                            val audioBufferInfo = MediaCodec.BufferInfo()

                            while (true) {
                                val sampleSize = audioExtractor.readSampleData(buffer, 0)
                                if (sampleSize < 0) break

                                audioBufferInfo.presentationTimeUs = audioExtractor.sampleTime
                                audioBufferInfo.size = sampleSize
                                audioBufferInfo.flags = audioExtractor.sampleFlags

                                muxer.writeSampleData(audioMuxerTrackIndex, buffer, audioBufferInfo)
                                if (!audioExtractor.advance()) break
                            }
                            audioExtractor.release()
                        }
                    }
                }
                encoderOutputIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(encoderOutputIndex)!!

                    if (bufferInfo.size != 0) {
                        if (!muxerStarted) {
                            throw RuntimeException("Muxer hasn't started")
                        }
                        muxer.writeSampleData(muxerTrackIndex, outputBuffer, bufferInfo)
                    }

                    encoder.releaseOutputBuffer(encoderOutputIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }
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
        // Use simpler re-encoding method to avoid OpenGL artifacts
        // The OpenGL-based VideoProcessor can cause black artifacts due to surface synchronization issues
        cropVideoWithSimpleReencoding(inputPath, outputPath, cropX, cropY, cropWidth, cropHeight)
    }

    private fun cropVideoWithSimpleReencoding(
        inputPath: String,
        outputPath: String,
        cropX: Int,
        cropY: Int,
        cropWidth: Int,
        cropHeight: Int
    ) {
        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)

        // Find video track
        var videoTrackIndex = -1
        var videoFormat: MediaFormat? = null

        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) {
                videoTrackIndex = i
                videoFormat = format
                extractor.selectTrack(i)
                break
            }
        }

        if (videoTrackIndex == -1 || videoFormat == null) {
            throw Exception("No video track found")
        }

        // Get original dimensions and rotation
        val originalWidth = videoFormat.getInteger(MediaFormat.KEY_WIDTH)
        val originalHeight = videoFormat.getInteger(MediaFormat.KEY_HEIGHT)
        val rotation = if (videoFormat.containsKey(MediaFormat.KEY_ROTATION)) {
            videoFormat.getInteger(MediaFormat.KEY_ROTATION)
        } else {
            0
        }

        // Handle rotation - swap dimensions if needed
        val (displayWidth, displayHeight) = when (rotation) {
            90, 270 -> originalHeight to originalWidth
            else -> originalWidth to originalHeight
        }

        // Validate crop parameters
        if (cropX < 0 || cropY < 0 ||
            cropX + cropWidth > displayWidth ||
            cropY + cropHeight > displayHeight) {
            throw IllegalArgumentException("Invalid crop parameters")
        }

        // Setup decoder
        val mime = videoFormat.getString(MediaFormat.KEY_MIME)!!
        val decoder = MediaCodec.createDecoderByType(mime)

        // Debug: Original video: ${originalWidth}x${originalHeight}, rotation: $rotation
        // Debug: Display dimensions: ${displayWidth}x${displayHeight}
        // Debug: Crop parameters: x=$cropX, y=$cropY, w=$cropWidth, h=$cropHeight

        // Setup encoder with crop dimensions
        val outputFormat = MediaFormat.createVideoFormat("video/avc", cropWidth, cropHeight).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)

            // Safely get bit rate with fallback
            val originalBitRate = if (videoFormat.containsKey(MediaFormat.KEY_BIT_RATE)) {
                try {
                    videoFormat.getInteger(MediaFormat.KEY_BIT_RATE)
                } catch (e: Exception) {
                    1000000 // 1Mbps fallback
                }
            } else {
                1000000 // 1Mbps fallback
            }
            setInteger(MediaFormat.KEY_BIT_RATE, originalBitRate)

            // Use original frame rate instead of hardcoded 30fps to prevent artifacts
            val originalFrameRate = if (videoFormat.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                try {
                    videoFormat.getInteger(MediaFormat.KEY_FRAME_RATE)
                } catch (e: Exception) {
                    30 // fallback to 30fps if not available
                }
            } else {
                30 // fallback to 30fps if not available
            }
            setInteger(MediaFormat.KEY_FRAME_RATE, originalFrameRate)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        val encoder = MediaCodec.createEncoderByType("video/avc")
        encoder.configure(outputFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = encoder.createInputSurface()
        encoder.start()

        // Configure decoder with output surface
        decoder.configure(videoFormat, inputSurface, null, 0)
        decoder.start()

        // Setup muxer
        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var muxerTrackIndex = -1
        var muxerStarted = false

        // Audio handling
        val audioExtractor = MediaExtractor()
        audioExtractor.setDataSource(inputPath)
        var audioTrackIndex = -1
        var audioFormat: MediaFormat? = null
        var audioMuxerTrackIndex = -1

        // Find and setup audio track
        for (i in 0 until audioExtractor.trackCount) {
            val format = audioExtractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) {
                audioTrackIndex = i
                audioFormat = format
                audioExtractor.selectTrack(i)

                // Setup audio passthrough
                audioMuxerTrackIndex = muxer.addTrack(format)
                break
            }
        }

        // Processing loop
        val bufferInfo = MediaCodec.BufferInfo()
        val audioBufferInfo = MediaCodec.BufferInfo()
        var outputDone = false
        var inputDone = false
        var audioOutputDone = audioTrackIndex == -1

        val timeoutUs = 10000L
        val startTime = System.nanoTime()

        // Start processing
        while (!outputDone) {
            // Feed input to decoder
            if (!inputDone) {
                val inputBufferIndex = decoder.dequeueInputBuffer(timeoutUs)
                if (inputBufferIndex >= 0) {
                    val inputBuffer = decoder.getInputBuffer(inputBufferIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)

                    if (sampleSize < 0) {
                        decoder.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        val sampleTime = extractor.sampleTime
                        decoder.queueInputBuffer(inputBufferIndex, 0, sampleSize, sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            // Get output from decoder (renders to encoder's input surface automatically)
            val decoderOutputIndex = decoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            if (decoderOutputIndex >= 0) {
                val doRender = bufferInfo.size != 0
                decoder.releaseOutputBuffer(decoderOutputIndex, doRender)

                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    encoder.signalEndOfInputStream()
                }
            }

            // Get output from encoder
            val encoderOutputIndex = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            when {
                encoderOutputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (!muxerStarted) {
                        val newFormat = encoder.outputFormat
                        muxerTrackIndex = muxer.addTrack(newFormat)

                        // Add audio track BEFORE starting muxer
                        var audioMuxerTrackIndex = -1
                        if (audioTrackIndex >= 0 && audioFormat != null) {
                            audioMuxerTrackIndex = muxer.addTrack(audioFormat)
                        }

                        muxer.start()
                        muxerStarted = true

                        // Process audio track AFTER muxer is started
                        if (audioMuxerTrackIndex >= 0) {
                            val audioExtractor = MediaExtractor()
                            audioExtractor.setDataSource(inputPath)
                            audioExtractor.selectTrack(audioTrackIndex)

                            val buffer = ByteBuffer.allocate(1024 * 1024)
                            val audioBufferInfo = MediaCodec.BufferInfo()

                            while (true) {
                                val sampleSize = audioExtractor.readSampleData(buffer, 0)
                                if (sampleSize < 0) break

                                audioBufferInfo.presentationTimeUs = audioExtractor.sampleTime
                                audioBufferInfo.size = sampleSize
                                audioBufferInfo.flags = audioExtractor.sampleFlags

                                muxer.writeSampleData(audioMuxerTrackIndex, buffer, audioBufferInfo)
                                if (!audioExtractor.advance()) break
                            }
                            audioExtractor.release()
                        }
                    }
                }
                encoderOutputIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(encoderOutputIndex)!!

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size != 0 && muxerStarted) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(muxerTrackIndex, outputBuffer, bufferInfo)
                    }

                    encoder.releaseOutputBuffer(encoderOutputIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }

            // Process audio passthrough
            if (!audioOutputDone && muxerStarted && audioTrackIndex >= 0) {
                val audioBuffer = ByteBuffer.allocate(256 * 1024)
                val sampleSize = audioExtractor.readSampleData(audioBuffer, 0)

                if (sampleSize < 0) {
                    audioOutputDone = true
                } else {
                    audioBufferInfo.offset = 0
                    audioBufferInfo.size = sampleSize
                    audioBufferInfo.presentationTimeUs = audioExtractor.sampleTime
                    audioBufferInfo.flags = audioExtractor.sampleFlags

                    muxer.writeSampleData(audioMuxerTrackIndex, audioBuffer, audioBufferInfo)
                    audioExtractor.advance()
                }
            }

            // Timeout check
            if (System.nanoTime() - startTime > 30_000_000_000L) { // 30 seconds timeout
                throw Exception("Video processing timeout")
            }
        }

        // Cleanup
        decoder.stop()
        decoder.release()
        encoder.stop()
        encoder.release()
        extractor.release()
        audioExtractor.release()
        muxer.stop()
        muxer.release()
        inputSurface.release()
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
                // Collect all transformation parameters
                val trimStartMs = call.argument<Int>("trimStartMs")?.toLong()
                val trimEndMs = call.argument<Int>("trimEndMs")?.toLong()
                val rotateDegrees = call.argument<Int>("rotateDegrees")
                val cropX = call.argument<Int>("cropX")
                val cropY = call.argument<Int>("cropY")
                val cropWidth = call.argument<Int>("cropWidth")
                val cropHeight = call.argument<Int>("cropHeight")

                Log.i(TAG, "Processing video with transformations:")
                Log.i(TAG, "  Trim: ${if (trimStartMs != null) "$trimStartMs-$trimEndMs ms" else "none"}")
                Log.i(TAG, "  Rotate: ${rotateDegrees ?: "none"} degrees")
                Log.i(TAG, "  Crop: ${if (cropX != null) "[$cropX,$cropY ${cropWidth}x$cropHeight]" else "none"}")

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
                        Log.d(TAG, "Processing progress: ${(progress * 100).toInt()}%")
                        withContext(Dispatchers.Main) {
                            progressEventSink?.success(progress)
                        }
                    }
                )

                val processingSteps = mutableListOf<String>()
                if (trimStartMs != null) processingSteps.add("Trim")
                if (rotateDegrees != null && rotateDegrees != 0) processingSteps.add("Rotate")
                if (cropX != null) processingSteps.add("Crop")

                Log.i(TAG, "Video processing completed:")
                Log.i(TAG, "  Steps: ${processingSteps.joinToString(", ")}")
                Log.i(TAG, "  Total time: ${processingResult.processingTimeMs}ms")
                Log.i(TAG, "  Re-encoded: ${processingResult.isReEncoded}")

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
                Log.e(TAG, "Process video failed", e)
                withContext(Dispatchers.Main) {
                    result.error("PROCESS_ERROR", e.message, null)
                }
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