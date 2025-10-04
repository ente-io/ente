import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:native_video_editor/native_video_editor.dart';
import 'package:video_editor/video_editor.dart';

/// Service that uses native video editing operations when possible
/// Falls back to FFmpeg for operations that require re-encoding
class NativeVideoExportService {
  static final _logger = Logger('NativeVideoExportService');

  /// Export video using native operations when possible
  static Future<File> exportVideo({
    required VideoEditorController controller,
    required String outputPath,
    int metadataRotation = 0,
    void Function(double)? onProgress,
    void Function(Object, StackTrace)? onError,
  }) async {
    final startTime = DateTime.now();
    try {
      final inputPath = controller.file.path;

      // Analyze what operations are needed
      final needsTrim = controller.isTrimmed;
      final needsRotation = controller.rotation != 0;
      final needsCrop = controller.minCrop != Offset.zero ||
          controller.maxCrop != const Offset(1.0, 1.0);

      // Determine if we can use native operations
      final canUseNative = _canUseNativeOperations(
        needsTrim: needsTrim,
        needsRotation: needsRotation,
        needsCrop: needsCrop,
        controller: controller,
      );

      if (canUseNative) {
        // Use native operations
        final result = await _performNativeOperations(
          inputPath: inputPath,
          outputPath: outputPath,
          controller: controller,
          metadataRotation: metadataRotation,
          onProgress: onProgress,
        );

        return File(result.outputPath);
      } else {
        // Still use native export even for crop operations
        final result = await _performNativeOperations(
          inputPath: inputPath,
          outputPath: outputPath,
          controller: controller,
          metadataRotation: metadataRotation,
          onProgress: onProgress,
        );

        return File(result.outputPath);
      }
    } catch (error, stackTrace) {
      final elapsed = DateTime.now().difference(startTime);
      _logger.warning(
        'Native export failed after ${elapsed.inMilliseconds}ms.',
        error,
        stackTrace,
      );

      if (onError != null) {
        onError(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Check if we can use native operations for the required edits
  static bool _canUseNativeOperations({
    required bool needsTrim,
    required bool needsRotation,
    required bool needsCrop,
    required VideoEditorController controller,
  }) {
    // Native operations support:
    // - Trim: Yes (without re-encoding)
    // - Rotation: Yes (metadata on Android, transform on iOS)
    // - Crop: Limited (requires re-encoding on iOS, not implemented on Android)

    // Allow native operations even for crop (we'll handle it natively)
    // if (needsCrop) {
    //   return false;
    // }

    // No video effects API available in current VideoEditorController
    // If we add filters/effects in the future, check for them here

    return true;
  }

  /// Perform native video operations
  static Future<VideoEditResult> _performNativeOperations({
    required String inputPath,
    required String outputPath,
    required VideoEditorController controller,
    int metadataRotation = 0,
    void Function(double)? onProgress,
  }) async {
    final needsCrop = controller.minCrop != Offset.zero ||
        controller.maxCrop != const Offset(1.0, 1.0);

    // If we need multiple operations, use the combined processVideo method
    if (controller.isTrimmed || controller.rotation != 0 || needsCrop) {
      Duration? trimStart;
      Duration? trimEnd;
      int? rotateDegrees;
      Rect? cropRect;

      if (controller.isTrimmed) {
        trimStart = controller.startTrim;
        trimEnd = controller.endTrim;
      }

      if (controller.rotation != 0) {
        rotateDegrees = controller.rotation;
      }

      if (needsCrop) {
        // Calculate crop rectangle from controller's crop values
        final videoSize = controller.video.value.size;
        final metadataQuarterTurns = (metadataRotation / 90).round();

        if (Platform.isAndroid &&
            metadataRotation != 0 &&
            metadataQuarterTurns % 2 == 1) {
          // Android with 90°/270° rotation - use simple axis swap approach (matches FFmpeg)
          _logger.info(
            '[Native] Android $metadataRotation° rotation - using axis swap',
          );

          // DON'T swap coords - use display coords directly
          // File crop dimensions will naturally swap when rotation is applied
          final double minXNorm = controller.minCrop.dx;
          final double maxXNorm = controller.maxCrop.dx;
          final double minYNorm = controller.minCrop.dy;
          final double maxYNorm = controller.maxCrop.dy;

          _logger.info(
            '[Native] Display dims: ${videoSize.width}x${videoSize.height}',
          );
          _logger.info(
            '[Native] File dims (original): ${videoSize.height}x${videoSize.width}',
          );
          _logger.info(
            '[Native] Display crop: (${controller.minCrop.dx}, ${controller.minCrop.dy}) to (${controller.maxCrop.dx}, ${controller.maxCrop.dy})',
          );
          _logger.info(
            '[Native] After swap: ($minXNorm, $minYNorm) to ($maxXNorm, $maxYNorm)',
          );

          // Apply coords to correct dimensions
          // Display coords × Display dims, result gets swapped for file
          final double minX = (minXNorm * videoSize.width)
              .roundToDouble(); // Display X × display width
          final double maxX = (maxXNorm * videoSize.width).roundToDouble();
          final double minY = (minYNorm * videoSize.height)
              .roundToDouble(); // Display Y × display height
          final double maxY = (maxYNorm * videoSize.height).roundToDouble();

          cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);

          _logger.info(
            '[Native] File crop rect: minX=${minX.toInt()}, maxX=${maxX.toInt()}, minY=${minY.toInt()}, maxY=${maxY.toInt()}',
          );
          _logger.info(
            '[Native] File crop: x=${minX.toInt()}, y=${minY.toInt()}, w=${(maxX - minX).toInt()}, h=${(maxY - minY).toInt()}',
          );
        } else {
          // iOS or Android without rotation - use original complex logic
          final totalRotation = (metadataRotation + controller.rotation) % 360;
          final totalQuarterTurns = (totalRotation / 90).round();
          final shouldSwapDimensionsIOS = totalQuarterTurns % 2 == 1;
          final shouldSwapDimensions =
              Platform.isIOS && shouldSwapDimensionsIOS;

          final displayWidth =
              shouldSwapDimensions ? videoSize.height : videoSize.width;
          final displayHeight =
              shouldSwapDimensions ? videoSize.width : videoSize.height;

          double displayCropWidth =
              (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
          double displayCropHeight =
              (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;

          // Apply preferred aspect ratio constraint if set
          if (controller.preferredCropAspectRatio != null) {
            final targetAspectRatio = controller.preferredCropAspectRatio!;
            final currentAspectRatio = displayCropWidth / displayCropHeight;

            if (targetAspectRatio == 1.0) {
              final maxSquareSize = math.min(displayWidth, displayHeight);
              final rawWidth = (controller.maxCrop.dx - controller.minCrop.dx) *
                  displayWidth;
              final rawHeight =
                  (controller.maxCrop.dy - controller.minCrop.dy) *
                      displayHeight;
              final actualSquareSize =
                  math.min(rawWidth, math.min(rawHeight, maxSquareSize));

              displayCropWidth = actualSquareSize;
              displayCropHeight = actualSquareSize;
            } else if ((currentAspectRatio - targetAspectRatio).abs() > 0.01) {
              if (targetAspectRatio > currentAspectRatio) {
                displayCropWidth = displayCropHeight * targetAspectRatio;
                if (displayCropWidth > displayWidth) {
                  displayCropWidth = displayWidth;
                  displayCropHeight = displayCropWidth / targetAspectRatio;
                }
              } else {
                displayCropHeight = displayCropWidth / targetAspectRatio;
                if (displayCropHeight > displayHeight) {
                  displayCropHeight = displayHeight;
                  displayCropWidth = displayCropHeight * targetAspectRatio;
                }
              }
            }
          }

          double minXNorm = controller.minCrop.dx;
          double minYNorm = controller.minCrop.dy;
          double maxXNorm = controller.maxCrop.dx;
          double maxYNorm = controller.maxCrop.dy;

          // Transform coordinates for iOS rotated videos
          if (Platform.isIOS) {
            final normalizedTurns = ((totalQuarterTurns % 4) + 4) % 4;
            if (normalizedTurns != 0) {
              final transformed = _transformNormalizedCropForRotation(
                minX: minXNorm,
                maxX: maxXNorm,
                minY: minYNorm,
                maxY: maxYNorm,
                normalizedQuarterTurns: normalizedTurns,
              );
              minXNorm = transformed.minX;
              maxXNorm = transformed.maxX;
              minYNorm = transformed.minY;
              maxYNorm = transformed.maxY;
            }
          }

          minXNorm = math.min(math.max(minXNorm, 0), 1);
          maxXNorm = math.min(math.max(maxXNorm, 0), 1);
          minYNorm = math.min(math.max(minYNorm, 0), 1);
          maxYNorm = math.min(math.max(maxYNorm, 0), 1);

          if (minXNorm > maxXNorm) {
            final temp = minXNorm;
            minXNorm = maxXNorm;
            maxXNorm = temp;
          }
          if (minYNorm > maxYNorm) {
            final temp = minYNorm;
            minYNorm = maxYNorm;
            maxYNorm = temp;
          }

          // Apply to original video dimensions
          final double targetWidth = videoSize.width;
          final double targetHeight = videoSize.height;

          double minX = minXNorm * targetWidth;
          double maxX = maxXNorm * targetWidth;
          double minY = minYNorm * targetHeight;
          double maxY = maxYNorm * targetHeight;

          // iOS-specific: aspect ratio correction for rotated videos
          if (Platform.isIOS &&
              shouldSwapDimensions &&
              controller.preferredCropAspectRatio == 1.0) {
            final displayCropWidth =
                (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
            final displayCropHeight =
                (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;

            final scaledWidth =
                displayCropWidth * (videoSize.width / displayWidth);
            final scaledHeight =
                displayCropHeight * (videoSize.height / displayHeight);
            final squareSize = math.min(scaledWidth, scaledHeight);

            final centerX = (minX + maxX) / 2;
            final centerY = (minY + maxY) / 2;

            minX = centerX - squareSize / 2;
            maxX = centerX + squareSize / 2;
            minY = centerY - squareSize / 2;
            maxY = centerY + squareSize / 2;
          }

          cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);
        }

        // Validate crop parameters against original video dimensions
        // For Android with 90°/270° rotation, the crop is in original file space (swapped dimensions)
        final validationWidth =
            Platform.isAndroid && metadataQuarterTurns % 2 == 1
                ? videoSize.height
                : videoSize.width;
        final validationHeight =
            Platform.isAndroid && metadataQuarterTurns % 2 == 1
                ? videoSize.width
                : videoSize.height;

        if (cropRect.width <= 0 || cropRect.height <= 0) {
          throw Exception(
            'Invalid crop dimensions: width=${cropRect.width.toInt()}, height=${cropRect.height.toInt()}',
          );
        }
        if (cropRect.left < 0 || cropRect.top < 0) {
          throw Exception(
            'Invalid crop position: x=${cropRect.left.toInt()}, y=${cropRect.top.toInt()}',
          );
        }
        if (cropRect.right > validationWidth ||
            cropRect.bottom > validationHeight) {
          throw Exception(
            'Crop extends beyond video bounds: right=${cropRect.right.toInt()}, bottom=${cropRect.bottom.toInt()}, videoDim=${validationWidth.toInt()}x${validationHeight.toInt()}',
          );
        }
      }

      try {
        final result = await NativeVideoEditor.processVideo(
          inputPath: inputPath,
          outputPath: outputPath,
          trimStart: trimStart,
          trimEnd: trimEnd,
          rotateDegrees: rotateDegrees,
          cropRect: cropRect,
          onProgress: onProgress,
        );
        return result;
      } catch (e) {
        rethrow;
      }
    }

    // If no operations needed, just copy the file
    await File(inputPath).copy(outputPath);
    return VideoEditResult(
      outputPath: outputPath,
      isReEncoded: false,
      processingTime: Duration.zero,
    );
  }

  /// Get video information using native methods
  static Future<Map<String, dynamic>> getVideoInfo(String videoPath) async {
    try {
      return await NativeVideoEditor.getVideoInfo(videoPath);
    } catch (e) {
      // Fallback to MediaInfo or FFprobe if needed
      return {};
    }
  }

  /// Cancel any ongoing export operation
  static Future<void> cancelExport() async {
    try {
      // Cancel native operation
      await NativeVideoEditor.cancelProcessing();
    } catch (e) {
      // Silently fail
    }
  }

  /// Transform crop rectangle from rotated space to original video space
  static ({double minX, double maxX, double minY, double maxY})
      _transformNormalizedCropForRotation({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    required int normalizedQuarterTurns,
  }) {
    switch (normalizedQuarterTurns) {
      case 0:
        return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
      case 1:
        return (
          minX: 1 - maxY,
          maxX: 1 - minY,
          minY: minX,
          maxY: maxX,
        );
      case 2:
        return (
          minX: 1 - maxX,
          maxX: 1 - minX,
          minY: 1 - maxY,
          maxY: 1 - minY,
        );
      case 3:
        return (
          minX: minY,
          maxX: maxY,
          minY: 1 - maxX,
          maxY: 1 - minX,
        );
      default:
        return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
    }
  }
}
