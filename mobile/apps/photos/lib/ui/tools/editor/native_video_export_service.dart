import 'dart:async';
import 'dart:io';
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
        // IMPORTANT: When metadata rotation exists and we're displaying with swapped dimensions,
        // the crop grid viewer uses those swapped dimensions, so we must too
        final videoDimension = controller.videoDimension;
        final videoSize = controller.video.value.size;

        // Use swapped dimensions if metadata rotation exists (90 or 270)
        final cropCalcWidth =
            (metadataRotation == 90 || metadataRotation == 270)
                ? videoSize.height
                : videoSize.width;
        final cropCalcHeight =
            (metadataRotation == 90 || metadataRotation == 270)
                ? videoSize.width
                : videoSize.height;

        _logger('=== CROP CALCULATION DEBUG ===');
        _logger(
          'controller.videoDimension: ${videoDimension.width} x ${videoDimension.height}',
        );
        _logger(
          'controller.video.value.size: ${videoSize.width} x ${videoSize.height}',
        );
        _logger('metadataRotation: $metadataRotation degrees');
        _logger(
          'cropCalcWidth: $cropCalcWidth, cropCalcHeight: $cropCalcHeight (dimensions used by crop grid)',
        );
        _logger(
          'controller.video.value.aspectRatio: ${controller.video.value.aspectRatio}',
        );
        _logger('controller.rotation: ${controller.rotation}');
        _logger('controller.minCrop: ${controller.minCrop}');
        _logger('controller.maxCrop: ${controller.maxCrop}');
        _logger(
          'controller.preferredCropAspectRatio: ${controller.preferredCropAspectRatio}',
        );

        final minX = controller.minCrop.dx * cropCalcWidth;
        final minY = controller.minCrop.dy * cropCalcHeight;
        final maxX = controller.maxCrop.dx * cropCalcWidth;
        final maxY = controller.maxCrop.dy * cropCalcHeight;

        cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);
        _logger(
          'Calculated crop rect (display space): left=$minX, top=$minY, right=$maxX, bottom=$maxY',
        );
        _logger(
          'Crop rect dimensions (display space): width=${cropRect.width.toInt()}, height=${cropRect.height.toInt()}',
        );
        _logger(
          'Crop rect position (display space): x=${cropRect.left.toInt()}, y=${cropRect.top.toInt()}',
        );

        // NOTE: No coordinate transformation needed!
        // When metadataRotation exists, we already calculated crop using swapped dimensions
        // (cropCalcWidth/Height), so the coordinates are already in raw file space.
        _logger(
          'Crop coordinates are already in file space (no transformation needed)',
        );

        _logger(
          'Final crop to send to native: x=${cropRect.left.toInt()}, y=${cropRect.top.toInt()}, width=${cropRect.width.toInt()}, height=${cropRect.height.toInt()}',
        );
        _logger('===========================');

        // Validate crop parameters (use the same dimensions we used for calculation)
        final rawFileWidth = cropCalcWidth;
        final rawFileHeight = cropCalcHeight;

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
}
