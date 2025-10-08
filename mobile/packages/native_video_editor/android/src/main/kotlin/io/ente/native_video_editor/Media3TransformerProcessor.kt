package io.ente.native_video_editor

import android.content.Context
import android.util.Log
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.Size
import androidx.media3.effect.*
import androidx.media3.transformer.*
import kotlinx.coroutines.*
import java.io.File
import java.util.concurrent.CountDownLatch
import kotlin.math.roundToInt

/**
 * Processor using Media3 Transformer for efficient video editing operations.
 * Handles trim, rotate, and crop operations with proper effect chaining.
 */
class Media3TransformerProcessor(private val context: Context) {
    companion object {
        private const val TAG = "Media3Transformer"

        // Logging levels for debugging
        private const val LOG_VERBOSE = true
        private const val LOG_PROGRESS = true
        private const val LOG_ERRORS = true
    }

    /**
     * Process video with multiple transformations in a single pass
     */
    suspend fun processVideo(
        inputPath: String,
        outputPath: String,
        trimStartMs: Long? = null,
        trimEndMs: Long? = null,
        rotateDegrees: Int? = null,
        cropX: Int? = null,
        cropY: Int? = null,
        cropWidth: Int? = null,
        cropHeight: Int? = null,
        onProgress: ((Float) -> Unit)? = null
    ): ProcessingResult = withContext(Dispatchers.Main) {
        val startTime = System.currentTimeMillis()
        val latch = CountDownLatch(1)
        var processingError: Exception? = null
        var hasVideoEffects = false

        logVerbose("Starting video processing:")
        logVerbose("  Input: $inputPath")
        logVerbose("  Output: $outputPath")
        logVerbose("  Trim: ${if (trimStartMs != null) "$trimStartMs-$trimEndMs ms" else "none"}")
        logVerbose("  Rotate: ${rotateDegrees ?: "none"} degrees")
        logVerbose("  Crop: ${if (cropX != null) "[$cropX,$cropY ${cropWidth}x$cropHeight]" else "none"}")

        try {
            // Get video info first
            val videoInfo = getVideoInfo(inputPath)
            val originalWidth = videoInfo.width
            val originalHeight = videoInfo.height
            val originalRotation = videoInfo.rotation

            logVerbose("Original video: ${originalWidth}x$originalHeight, rotation=$originalRotation")

            // Build MediaItem with optional clipping
            val mediaItemBuilder = MediaItem.Builder().setUri(inputPath)

            if (trimStartMs != null && trimEndMs != null) {
                logVerbose("Applying trim: $trimStartMs-$trimEndMs ms")
                mediaItemBuilder.setClippingConfiguration(
                    MediaItem.ClippingConfiguration.Builder()
                        .setStartPositionMs(trimStartMs)
                        .setEndPositionMs(trimEndMs)
                        .setStartsAtKeyFrame(false) // Allow precise cuts
                        .build()
                )
            }

            val mediaItem = mediaItemBuilder.build()

            // Build effects list
            val videoEffects = mutableListOf<Effect>()

            // Add crop effect if needed BEFORE rotation
            // This ensures crop coordinates are applied to the correct orientation
            var outDimsFromCrop: Size? = null
            if (cropX != null && cropY != null && cropWidth != null && cropHeight != null) {
                // For videos with 90°/270° rotation in metadata, the UI provides
                // crop rect in display-space (dimensions swapped). We must map it
                // back to file-space (originalWidth x originalHeight) before
                // applying the crop effect.
                val normalizedRotation = ((originalRotation % 360) + 360) % 360
                val needsCoordinateTransform = normalizedRotation == 90 || normalizedRotation == 270

                val finalCropX: Int
                val finalCropY: Int
                val finalCropWidth: Int
                val finalCropHeight: Int
                val normalizationWidth: Int = originalWidth
                val normalizationHeight: Int = originalHeight

                if (needsCoordinateTransform) {
                    // Map display-space (x_d,y_d,w_d,h_d) to file-space (x_f,y_f,w_f,h_f)
                    // Using standard rotation mappings about the top-left origin.
                    // For 90° CW display correction:
                    //   x_f = W - (y_d + h_d)
                    //   y_f = x_d
                    //   w_f = h_d
                    //   h_f = w_d
                    // For 270° (i.e., 90° CCW) display correction:
                    //   x_f = y_d
                    //   y_f = H - (x_d + w_d)
                    //   w_f = h_d
                    //   h_f = w_d
                    if (normalizedRotation == 90) {
                        finalCropX = (normalizationWidth - (cropY + cropHeight)).coerceIn(0, normalizationWidth)
                        finalCropY = cropX.coerceIn(0, normalizationHeight)
                        finalCropWidth = cropHeight.coerceAtMost(normalizationWidth - finalCropX)
                        finalCropHeight = cropWidth.coerceAtMost(normalizationHeight - finalCropY)
                    } else { // 270
                        finalCropX = cropY.coerceIn(0, normalizationWidth)
                        finalCropY = (normalizationHeight - (cropX + cropWidth)).coerceIn(0, normalizationHeight)
                        finalCropWidth = cropHeight.coerceAtMost(normalizationWidth - finalCropX)
                        finalCropHeight = cropWidth.coerceAtMost(normalizationHeight - finalCropY)
                    }
                } else {
                    // No transformation needed; already in file-space
                    finalCropX = cropX
                    finalCropY = cropY
                    finalCropWidth = cropWidth
                    finalCropHeight = cropHeight
                }

                // Calculate crop as a fraction of the file-space dimensions
                val cropLeftFraction = finalCropX.toFloat() / normalizationWidth
                val cropRightFraction = (finalCropX + finalCropWidth).toFloat() / normalizationWidth
                val cropTopFraction = finalCropY.toFloat() / normalizationHeight
                val cropBottomFraction = (finalCropY + finalCropHeight).toFloat() / normalizationHeight

                // Use Crop effect with NDC coordinates (-1 to 1)
                val cropEffect = Crop(
                    /* left = */ -1f + 2f * cropLeftFraction,
                    /* right = */ -1f + 2f * cropRightFraction,
                    /* bottom = */ 1f - 2f * cropBottomFraction,
                    /* top = */ 1f - 2f * cropTopFraction
                )

                // Preserve output dimensions from the transformed crop; these are in file-space.
                outDimsFromCrop = Size(finalCropWidth, finalCropHeight)

                videoEffects.add(cropEffect)
                hasVideoEffects = true
            }

            // Add rotation effect AFTER crop
            if (rotateDegrees != null && rotateDegrees != 0) {
                val normalizedDegrees = rotateDegrees % 360
                logVerbose("Adding rotation effect: $normalizedDegrees degrees")

                // Use ScaleAndRotateTransformation for proper rotation support
                // Media3 uses positive degrees for clockwise rotation
                val rotationEffect = ScaleAndRotateTransformation.Builder()
                    .setRotationDegrees(normalizedDegrees.toFloat())
                    .build()

                videoEffects.add(rotationEffect)
                logVerbose("Added ScaleAndRotateTransformation with rotation: $normalizedDegrees degrees (clockwise)")

                hasVideoEffects = true
            }

            // Add Presentation effect to set output dimensions
            // Base output on the file-space crop dimensions we actually applied.
            if (outDimsFromCrop != null) {
                var outputWidth = outDimsFromCrop!!.width
                var outputHeight = outDimsFromCrop!!.height

                // If a user-requested rotation (not metadata) is applied after crop,
                // swap output dimensions for 90/270 degrees.
                if (rotateDegrees != null && (rotateDegrees % 180) != 0) {
                    val tmp = outputWidth
                    outputWidth = outputHeight
                    outputHeight = tmp
                }

                val presentationEffect = Presentation.createForWidthAndHeight(
                    outputWidth,
                    outputHeight,
                    Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP
                )
                videoEffects.add(presentationEffect)
            }

            // Configure Transformer
            val transformerBuilder = Transformer.Builder(context)
                .setTransformationRequest(
                    TransformationRequest.Builder()
                        .setVideoMimeType(MimeTypes.VIDEO_H264) // Use H.264 for compatibility
                        .build()
                )
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                        logVerbose("Export completed successfully")
                        logVerbose("Export result: duration=${exportResult.durationMs}ms, " +
                                  "size=${exportResult.fileSizeBytes} bytes")
                        latch.countDown()
                    }

                    override fun onError(
                        composition: Composition,
                        exportResult: ExportResult,
                        exportException: ExportException
                    ) {
                        logError("Export failed", exportException)
                        logError("Error code: ${exportException.errorCode}")
                        logError("Export result: ${exportResult}")
                        processingError = exportException
                        latch.countDown()
                    }
                })

            val transformer = transformerBuilder.build()

            // Create EditedMediaItem with effects
            val editedMediaItemBuilder = EditedMediaItem.Builder(mediaItem)

            // Apply effects if any
            if (videoEffects.isNotEmpty()) {
                logVerbose("Applying ${videoEffects.size} video effects to EditedMediaItem")
                val effects = Effects(
                    /* audioProcessors = */ emptyList(),
                    /* videoEffects = */ videoEffects
                )
                editedMediaItemBuilder.setEffects(effects)
            }

            val editedMediaItem = editedMediaItemBuilder.build()
            val sequence = EditedMediaItemSequence(listOf(editedMediaItem))
            val composition = Composition.Builder(listOf(sequence)).build()

            // Start export
            logVerbose("Starting export...")
            transformer.start(composition, outputPath)

            // Monitor progress
            val progressJob = launch {
                while (latch.count > 0) {
                    val progressHolder = ProgressHolder()
                    val progressState = transformer.getProgress(progressHolder)

                    when (progressState) {
                        Transformer.PROGRESS_STATE_NOT_STARTED -> {
                            logProgress("Progress: Not started")
                        }
                        Transformer.PROGRESS_STATE_WAITING_FOR_AVAILABILITY -> {
                            logProgress("Progress: Waiting for availability")
                        }
                        Transformer.PROGRESS_STATE_AVAILABLE -> {
                            val progress = progressHolder.progress / 100f
                            logProgress("Progress: ${(progress * 100).roundToInt()}%")
                            onProgress?.invoke(progress)
                        }
                        Transformer.PROGRESS_STATE_UNAVAILABLE -> {
                            logProgress("Progress: Unavailable")
                        }
                    }

                    delay(100)
                }
            }

            // Wait for completion
            withContext(Dispatchers.IO) {
                latch.await()
            }
            progressJob.cancel()

            // Check for errors
            processingError?.let { throw it }

            val processingTime = System.currentTimeMillis() - startTime
            logVerbose("Processing completed in ${processingTime}ms")

            // Verify output file exists
            val outputFile = File(outputPath)
            if (!outputFile.exists()) {
                throw VideoProcessingException("Output file was not created")
            }

            logVerbose("Output file size: ${outputFile.length()} bytes")

            ProcessingResult(
                outputPath = outputPath,
                processingTimeMs = processingTime,
                isReEncoded = hasVideoEffects || (trimStartMs != null),
                method = "Media3 Transformer"
            )

        } catch (e: Exception) {
            logError("Failed to process video", e)
            throw VideoProcessingException("Video processing failed: ${e.message}", e)
        }
    }

    /**
     * Dedicated trim operation for optimal performance
     */
    suspend fun trimVideo(
        inputPath: String,
        outputPath: String,
        startTimeMs: Long,
        endTimeMs: Long,
        onProgress: ((Float) -> Unit)? = null
    ): ProcessingResult {
        return processVideo(
            inputPath = inputPath,
            outputPath = outputPath,
            trimStartMs = startTimeMs,
            trimEndMs = endTimeMs,
            onProgress = onProgress
        )
    }

    /**
     * Dedicated rotate operation
     */
    suspend fun rotateVideo(
        inputPath: String,
        outputPath: String,
        degrees: Int,
        onProgress: ((Float) -> Unit)? = null
    ): ProcessingResult {
        return processVideo(
            inputPath = inputPath,
            outputPath = outputPath,
            rotateDegrees = degrees,
            onProgress = onProgress
        )
    }

    /**
     * Dedicated crop operation
     */
    suspend fun cropVideo(
        inputPath: String,
        outputPath: String,
        cropX: Int,
        cropY: Int,
        cropWidth: Int,
        cropHeight: Int,
        onProgress: ((Float) -> Unit)? = null
    ): ProcessingResult {
        return processVideo(
            inputPath = inputPath,
            outputPath = outputPath,
            cropX = cropX,
            cropY = cropY,
            cropWidth = cropWidth,
            cropHeight = cropHeight,
            onProgress = onProgress
        )
    }

    /**
     * Get video information
     */
    private fun getVideoInfo(videoPath: String): VideoInfo {
        val retriever = android.media.MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoPath)

            VideoInfo(
                width = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
                )?.toIntOrNull() ?: 0,
                height = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
                )?.toIntOrNull() ?: 0,
                rotation = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION
                )?.toIntOrNull() ?: 0,
                duration = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_DURATION
                )?.toLongOrNull() ?: 0L,
                bitrate = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_BITRATE
                )?.toLongOrNull() ?: 0L
            )
        } finally {
            retriever.release()
        }
    }

    // Logging helpers
    private fun logVerbose(message: String) {
        if (LOG_VERBOSE) Log.d(TAG, message)
    }

    private fun logProgress(message: String) {
        if (LOG_PROGRESS) Log.i(TAG, message)
    }

    private fun logError(message: String, throwable: Throwable? = null) {
        if (LOG_ERRORS) {
            if (throwable != null) {
                Log.e(TAG, message, throwable)
            } else {
                Log.e(TAG, message)
            }
        }
    }
}

/**
 * Video information data class
 */
private data class VideoInfo(
    val width: Int,
    val height: Int,
    val rotation: Int,
    val duration: Long,
    val bitrate: Long
)

/**
 * Result of video processing operation
 */
data class ProcessingResult(
    val outputPath: String,
    val processingTimeMs: Long,
    val isReEncoded: Boolean,
    val method: String
)

/**
 * Custom exception for video processing errors
 */
class VideoProcessingException(message: String, cause: Throwable? = null) : Exception(message, cause)
