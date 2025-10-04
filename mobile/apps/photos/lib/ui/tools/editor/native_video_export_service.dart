import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:native_video_editor/native_video_editor.dart';
import 'package:photos/ui/tools/editor/export_video_service.dart';
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
        'Native export failed after ${elapsed.inMilliseconds}ms. '
        'Falling back to FFmpeg if allowed.',
        error,
        stackTrace,
      );

      if (elapsed < const Duration(seconds: 3)) {
        onProgress?.call(0.0);
        try {
          return await ExportService.exportVideo(
            controller: controller,
            outputPath: outputPath,
            onProgress: onProgress,
            onError: onError,
          );
        } catch (ffmpegError, ffmpegStackTrace) {
          _logger.severe(
            'Fallback FFmpeg export also failed.',
            ffmpegError,
            ffmpegStackTrace,
          );
          if (onError != null) {
            onError(ffmpegError, ffmpegStackTrace);
          }
          rethrow;
        }
      }

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
        // The controller's crop values are in the displayed/rotated space
        final videoSize = controller.video.value.size;

        // Calculate total rotation (metadata + user rotation)
        final totalRotation = (metadataRotation + controller.rotation) % 360;
        final totalQuarterTurns = (totalRotation / 90).round();

        // For Android: native code applies only user rotation, so swap based on user rotation
        // For iOS: native code handles total rotation, so swap based on total rotation
        final userQuarterTurns = (controller.rotation / 90).round();
        final shouldSwapDimensionsAndroid = userQuarterTurns % 2 == 1;
        final shouldSwapDimensionsIOS = totalQuarterTurns % 2 == 1;
        final shouldSwapDimensions = Platform.isAndroid
            ? shouldSwapDimensionsAndroid
            : shouldSwapDimensionsIOS;

        // IMPORTANT: The controller's crop coordinates are normalized (0-1) values
        // that apply to the DISPLAYED video after user rotation.
        // We need to calculate the crop in the displayed space first,
        // then transform it back to the original video space.

        // For the displayed video dimensions after user rotation:
        final displayWidth =
            shouldSwapDimensions ? videoSize.height : videoSize.width;
        final displayHeight =
            shouldSwapDimensions ? videoSize.width : videoSize.height;

        // Calculate what the crop dimensions should be in display space
        double displayCropWidth =
            (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
        double displayCropHeight =
            (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;

        // Apply preferred aspect ratio constraint if set
        if (controller.preferredCropAspectRatio != null) {
          final targetAspectRatio = controller.preferredCropAspectRatio!;
          final currentAspectRatio = displayCropWidth / displayCropHeight;

          // The controller values don't enforce the aspect ratio, only the UI does
          // We need to calculate what the actual constrained crop should be

          if (targetAspectRatio == 1.0) {
            // For square crops, use the maximum square that fits
            // The UI shows the largest possible square within the video bounds
            final maxSquareSize = math.min(displayWidth, displayHeight);

            // Calculate the actual square size (it's constrained by the smaller of the raw dimensions)
            final rawWidth =
                (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
            final rawHeight =
                (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;
            final actualSquareSize =
                math.min(rawWidth, math.min(rawHeight, maxSquareSize));

            displayCropWidth = actualSquareSize;
            displayCropHeight = actualSquareSize;
          } else if ((currentAspectRatio - targetAspectRatio).abs() > 0.01) {
            // For other aspect ratios, constrain based on the target
            if (targetAspectRatio > currentAspectRatio) {
              // Need wider crop
              displayCropWidth = displayCropHeight * targetAspectRatio;
              if (displayCropWidth > displayWidth) {
                displayCropWidth = displayWidth;
                displayCropHeight = displayCropWidth / targetAspectRatio;
              }
            } else {
              // Need taller crop
              displayCropHeight = displayCropWidth / targetAspectRatio;
              if (displayCropHeight > displayHeight) {
                displayCropHeight = displayHeight;
                displayCropWidth = displayCropHeight * targetAspectRatio;
              }
            }
          }
        }

        // The crop values from the controller are normalized (0-1) in the DISPLAYED space
        // We need to interpret them correctly based on whether dimensions are swapped
        double minXNorm = controller.minCrop.dx;
        double minYNorm = controller.minCrop.dy;
        double maxXNorm = controller.maxCrop.dx;
        double maxYNorm = controller.maxCrop.dy;

        // Transform coordinates for rotated videos
        // iOS: metadata rotation is baked in, needs transformation to map display coords back
        // Android: native code does crop-then-rotate, so NO transformation needed
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
        double minX = minXNorm * videoSize.width;
        double maxX = maxXNorm * videoSize.width;
        double minY = minYNorm * videoSize.height;
        double maxY = maxYNorm * videoSize.height;

        // When dimensions were swapped in display, we need to apply aspect ratio correction
        // This is iOS-specific logic for handling rotated videos with aspect ratio constraints
        if (Platform.isIOS &&
            shouldSwapDimensions &&
            controller.preferredCropAspectRatio == 1.0) {
          // The crop in display space was 547x1729, but we need to scale it properly
          // Display space: 1080x1920 (portrait) -> Original space: 1920x1080 (landscape)

          // Calculate what the square size should be based on the display crop
          // We take the smaller dimension from display and scale it appropriately
          final displayCropWidth =
              (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
          final displayCropHeight =
              (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;

          // The correct square size is the minimum dimension scaled to the original aspect ratio
          // For a 547 width in 1080 display -> 547/1080 * 1920 = 973 in original width
          // For a 1729 height in 1920 display -> 1729/1920 * 1080 = 973 in original height
          final scaledWidth =
              displayCropWidth * (videoSize.width / displayWidth);
          final scaledHeight =
              displayCropHeight * (videoSize.height / displayHeight);
          final squareSize = math.min(scaledWidth, scaledHeight);

          // Center the square crop
          final centerX = (minX + maxX) / 2;
          final centerY = (minY + maxY) / 2;

          minX = centerX - squareSize / 2;
          maxX = centerX + squareSize / 2;
          minY = centerY - squareSize / 2;
          maxY = centerY + squareSize / 2;
        }

        cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);

        // Validate crop parameters against original video dimensions
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
        if (cropRect.right > videoSize.width ||
            cropRect.bottom > videoSize.height) {
          throw Exception(
            'Crop extends beyond video bounds: right=${cropRect.right.toInt()}, bottom=${cropRect.bottom.toInt()}, videoDim=${videoSize.width.toInt()}x${videoSize.height.toInt()}',
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
