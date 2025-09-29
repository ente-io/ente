import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:native_video_editor/native_video_editor.dart';
import 'package:video_editor/video_editor.dart';

/// Service that uses native video editing operations when possible
/// Falls back to FFmpeg for operations that require re-encoding
class NativeVideoExportService {
  static void _logger(String message) {
    // ignore: avoid_print
    print(' [NativeVideoExportService] $message');
  }

  /// Export video using native operations when possible
  static Future<File> exportVideo({
    required VideoEditorController controller,
    required String outputPath,
    int metadataRotation = 0,
    void Function(double)? onProgress,
    void Function(Object, StackTrace)? onError,
  }) async {
    try {
      final inputPath = controller.file.path;
      _logger('Starting export from $inputPath to $outputPath');
      _logger('Input file exists: ${File(inputPath).existsSync()}');
      _logger('Input file size: ${File(inputPath).lengthSync()} bytes');
      _logger('Metadata rotation: $metadataRotation degrees');

      // Analyze what operations are needed
      final needsTrim = controller.isTrimmed;
      final needsRotation = controller.rotation != 0;
      final needsCrop = controller.minCrop != Offset.zero ||
          controller.maxCrop != const Offset(1.0, 1.0);

      _logger(
        'Export operations needed: trim=$needsTrim, rotation=$needsRotation, crop=$needsCrop',
      );
      if (needsTrim) {
        _logger(
          'Trim details: start=${controller.startTrim}, end=${controller.endTrim}',
        );
      }
      if (needsRotation) {
        _logger('Rotation degrees: ${controller.rotation}');
      }

      // Determine if we can use native operations
      final canUseNative = _canUseNativeOperations(
        needsTrim: needsTrim,
        needsRotation: needsRotation,
        needsCrop: needsCrop,
        controller: controller,
      );

      _logger('Can use native operations: $canUseNative');

      if (canUseNative) {
        _logger('Attempting native video export...');

        // Use native operations
        final result = await _performNativeOperations(
          inputPath: inputPath,
          outputPath: outputPath,
          controller: controller,
          metadataRotation: metadataRotation,
          onProgress: onProgress,
        );

        _logger('Native export succeeded!');
        if (!result.isReEncoded) {
          _logger(
            'Video exported without re-encoding in ${result.processingTime?.inMilliseconds}ms',
          );
        } else {
          _logger(
            'Video exported with re-encoding in ${result.processingTime?.inMilliseconds}ms',
          );
        }

        return File(result.outputPath);
      } else {
        _logger(
          'Cannot use native operations for crop - using native export anyway',
        );
        // Still use native export even for crop operations
        _logger('Attempting native video export for crop operations...');

        final result = await _performNativeOperations(
          inputPath: inputPath,
          outputPath: outputPath,
          controller: controller,
          metadataRotation: metadataRotation,
          onProgress: onProgress,
        );

        _logger('Native export succeeded!');
        return File(result.outputPath);
      }
    } catch (e, s) {
      _logger('ERROR in native export: ${e.runtimeType}: $e');
      _logger('Error details: $e');
      _logger('Stack trace: $s');

      if (onError != null) {
        onError(e, s);
      }

      // Re-throw the error instead of falling back to FFmpeg
      _logger('Native export failed - rethrowing error');
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
    _logger('_performNativeOperations called');
    _logger('Input path: $inputPath');
    _logger('Output path: $outputPath');

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
        _logger(
          'Will trim from ${trimStart.inMilliseconds}ms to ${trimEnd.inMilliseconds}ms',
        );
      }

      if (controller.rotation != 0) {
        rotateDegrees = controller.rotation;
        _logger('Will rotate by $rotateDegrees degrees');
      }

      if (needsCrop) {
        // Calculate crop rectangle from controller's crop values
        // The controller's crop values are in the displayed/rotated space
        final videoDimension = controller.videoDimension;
        final videoSize = controller.video.value.size;

        // Calculate total rotation (metadata + user rotation)
        final totalRotation = (metadataRotation + controller.rotation) % 360;
        final totalQuarterTurns = (totalRotation / 90).round();
        final shouldSwapDimensions = totalQuarterTurns % 2 == 1;

        // IMPORTANT: The controller's crop coordinates are normalized (0-1) values
        // that apply to the DISPLAYED video after user rotation.
        // We need to calculate the crop in the displayed space first,
        // then transform it back to the original video space.

        // For the displayed video dimensions after user rotation:
        final displayWidth = shouldSwapDimensions ? videoSize.height : videoSize.width;
        final displayHeight = shouldSwapDimensions ? videoSize.width : videoSize.height;

        _logger('=== CROP CALCULATION DEBUG ===');
        _logger(
          'Original video dimensions: ${videoSize.width} x ${videoSize.height}',
        );
        _logger(
          'controller.videoDimension: ${videoDimension.width} x ${videoDimension.height}',
        );
        _logger('metadataRotation: $metadataRotation degrees');
        _logger('userRotation: ${controller.rotation} degrees');
        _logger('totalRotation: $totalRotation degrees');
        _logger('totalQuarterTurns: $totalQuarterTurns');
        _logger('shouldSwapDimensions for export: $shouldSwapDimensions');
        _logger(
          'Display dimensions (after rotation): $displayWidth x $displayHeight',
        );

        // Calculate what the crop dimensions should be in display space
        double displayCropWidth = (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
        double displayCropHeight = (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;

        // Apply preferred aspect ratio constraint if set
        if (controller.preferredCropAspectRatio != null) {
          final targetAspectRatio = controller.preferredCropAspectRatio!;
          final currentAspectRatio = displayCropWidth / displayCropHeight;

          _logger('Raw crop in display space: ${displayCropWidth.toInt()}x${displayCropHeight.toInt()}');
          _logger('Raw display space aspect ratio: ${currentAspectRatio}');
          _logger('Target aspect ratio: ${targetAspectRatio}');

          // The controller values don't enforce the aspect ratio, only the UI does
          // We need to calculate what the actual constrained crop should be

          if (targetAspectRatio == 1.0) {
            // For square crops, use the maximum square that fits
            // The UI shows the largest possible square within the video bounds
            final maxSquareSize = math.min(displayWidth, displayHeight);

            // The crop is centered, so calculate based on that
            final centerX = (controller.minCrop.dx + controller.maxCrop.dx) / 2;
            final centerY = (controller.minCrop.dy + controller.maxCrop.dy) / 2;

            // Calculate the actual square size (it's constrained by the smaller of the raw dimensions)
            final rawWidth = (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
            final rawHeight = (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;
            final actualSquareSize = math.min(rawWidth, math.min(rawHeight, maxSquareSize));

            displayCropWidth = actualSquareSize;
            displayCropHeight = actualSquareSize;

            _logger('Applied 1:1 constraint: ${actualSquareSize.toInt()}x${actualSquareSize.toInt()} square');
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
            _logger('Constrained crop to aspect ratio $targetAspectRatio: ${displayCropWidth.toInt()}x${displayCropHeight.toInt()}');
          }
        }

        _logger('Final crop in display space: ${displayCropWidth.toInt()}x${displayCropHeight.toInt()}');
        _logger('Display space aspect ratio: ${displayCropWidth / displayCropHeight}');
        _logger('=== CROP PARAMETERS ===');
        _logger(
          'controller.video.value.aspectRatio: ${controller.video.value.aspectRatio}',
        );
        _logger('controller.rotation: ${controller.rotation}');
        _logger('controller.minCrop: ${controller.minCrop}');
        _logger('controller.maxCrop: ${controller.maxCrop}');
        _logger(
          'controller.preferredCropAspectRatio: ${controller.preferredCropAspectRatio}',
        );

        // The crop values from the controller are normalized (0-1) in the DISPLAYED space
        // We need to interpret them correctly based on whether dimensions are swapped
        double minXNorm = controller.minCrop.dx;
        double minYNorm = controller.minCrop.dy;
        double maxXNorm = controller.maxCrop.dx;
        double maxYNorm = controller.maxCrop.dy;

        _logger('=== CROP RECT CALCULATION ===');
        _logger('Controller normalized crop (in display space): min=($minXNorm, $minYNorm), max=($maxXNorm, $maxYNorm)');
        _logger('These coords apply to display dimensions: ${displayWidth}x${displayHeight}');

        // Simple transformation based on rotation
        final normalizedTurns = ((totalQuarterTurns % 4) + 4) % 4;
        if (normalizedTurns != 0) {
          _logger('Video is rotated by ${normalizedTurns * 90} degrees - transforming coordinates');
          final transformed = _transformNormalizedCropForRotation(
            minX: minXNorm,
            maxX: maxXNorm,
            minY: minYNorm,
            maxY: maxYNorm,
            normalizedQuarterTurns: normalizedTurns,
          );
          _logger(
            'Transformed normalized crop: min=(${transformed.minX}, ${transformed.minY}), max=(${transformed.maxX}, ${transformed.maxY})',
          );
          minXNorm = transformed.minX;
          maxXNorm = transformed.maxX;
          minYNorm = transformed.minY;
          maxYNorm = transformed.maxY;
        } else {
          _logger('Video is not rotated - using normalized crop coordinates as-is');
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

        _logger('Final normalized coords (for original video): minX=$minXNorm, maxX=$maxXNorm, minY=$minYNorm, maxY=$maxYNorm');
        _logger('Normalized width: ${maxXNorm - minXNorm}, height: ${maxYNorm - minYNorm}');

        // Apply to original video dimensions
        double minX = minXNorm * videoSize.width;
        double maxX = maxXNorm * videoSize.width;
        double minY = minYNorm * videoSize.height;
        double maxY = maxYNorm * videoSize.height;

        // When dimensions were swapped in display, we need to apply aspect ratio correction
        if (shouldSwapDimensions && controller.preferredCropAspectRatio == 1.0) {
          // The crop in display space was 547x1729, but we need to scale it properly
          // Display space: 1080x1920 (portrait) -> Original space: 1920x1080 (landscape)

          // Calculate what the square size should be based on the display crop
          // We take the smaller dimension from display and scale it appropriately
          final displayCropWidth = (controller.maxCrop.dx - controller.minCrop.dx) * displayWidth;
          final displayCropHeight = (controller.maxCrop.dy - controller.minCrop.dy) * displayHeight;

          // The correct square size is the minimum dimension scaled to the original aspect ratio
          // For a 547 width in 1080 display -> 547/1080 * 1920 = 973 in original width
          // For a 1729 height in 1920 display -> 1729/1920 * 1080 = 973 in original height
          final scaledWidth = displayCropWidth * (videoSize.width / displayWidth);
          final scaledHeight = displayCropHeight * (videoSize.height / displayHeight);
          final squareSize = math.min(scaledWidth, scaledHeight);

          // Center the square crop
          final centerX = (minX + maxX) / 2;
          final centerY = (minY + maxY) / 2;

          minX = centerX - squareSize / 2;
          maxX = centerX + squareSize / 2;
          minY = centerY - squareSize / 2;
          maxY = centerY + squareSize / 2;

          _logger('Display crop was ${displayCropWidth.toInt()}x${displayCropHeight.toInt()}');
          _logger('Scaled dimensions: ${scaledWidth.toInt()}x${scaledHeight.toInt()}');
          _logger('Applied square constraint: ${squareSize.toInt()}x${squareSize.toInt()}');
        }

        cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);

        // Verify the crop makes sense
        _logger('Applying to original video (${videoSize.width}x${videoSize.height}):');
        _logger('  Pixel coords: x=${minX.toInt()}-${maxX.toInt()}, y=${minY.toInt()}-${maxY.toInt()}');
        _logger(
          'Calculated crop rect: ${cropRect.width.toInt()}x${cropRect.height.toInt()} at (${cropRect.left.toInt()}, ${cropRect.top.toInt()})',
        );
        _logger(
          'Expected aspect ratio: ${controller.preferredCropAspectRatio}',
        );
        _logger(
          'Actual aspect ratio: ${cropRect.width / cropRect.height}',
        );
        _logger('===========================');

        // Validate crop parameters against the original video dimensions
        final rawFileWidth = videoSize.width;
        final rawFileHeight = videoSize.height;

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
        if (cropRect.right > rawFileWidth || cropRect.bottom > rawFileHeight) {
          throw Exception(
            'Crop extends beyond video bounds: right=${cropRect.right.toInt()}, bottom=${cropRect.bottom.toInt()}, videoDim=${rawFileWidth}x$rawFileHeight',
          );
        }
      }

      _logger('Calling NativeVideoEditor.processVideo...');
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
        _logger('NativeVideoEditor.processVideo succeeded');
        return result;
      } catch (e, s) {
        _logger('NativeVideoEditor.processVideo failed: $e');
        _logger('Stack: $s');
        rethrow;
      }
    }

    // If no operations needed, just copy the file
    _logger('No operations needed, copying file directly');
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
      _logger('Error getting video info with native method: $e');
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
      _logger('Error cancelling export: $e');
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
    _logger(
      'Transform normalized crop: turns=$normalizedQuarterTurns, min=($minX, $minY), max=($maxX, $maxY)',
    );

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
