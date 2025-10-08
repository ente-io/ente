import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:native_video_editor/native_video_editor.dart';
import 'package:video_editor/video_editor.dart';
import 'package:photos/ui/tools/editor/video_crop_util.dart';

/// Service that uses native video editing operations when possible
/// Falls back to FFmpeg for operations that require re-encoding
class NativeVideoExportService {
  static final _logger = Logger('NativeVideoExportService');

  /// Export video using native operations
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

      // Always use the unified native operations path
      final result = await _performNativeOperations(
        inputPath: inputPath,
        outputPath: outputPath,
        controller: controller,
        metadataRotation: metadataRotation,
        onProgress: onProgress,
      );

      return File(result.outputPath);
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

  /// Perform native video operations
  static Future<VideoEditResult> _performNativeOperations({
    required String inputPath,
    required String outputPath,
    required VideoEditorController controller,
    int metadataRotation = 0,
    void Function(double)? onProgress,
  }) async {
    // Use the combined native path only when needed; otherwise do a fast copy
    final needsCrop = controller.minCrop != Offset.zero ||
        controller.maxCrop != const Offset(1.0, 1.0);
    final needsRotate = controller.rotation != 0;
    final needsTrim = controller.isTrimmed;

    if (!(needsCrop || needsRotate || needsTrim)) {
      await File(inputPath).copy(outputPath);
      return VideoEditResult(
        outputPath: outputPath,
        isReEncoded: false,
        processingTime: Duration.zero,
      );
    }

    Duration? trimStart;
    Duration? trimEnd;
    if (needsTrim) {
      trimStart = controller.startTrim;
      trimEnd = controller.endTrim;
    }

    final int? rotateDegrees = needsRotate ? controller.rotation : null;
    Rect? cropRect;
    if (needsCrop) {
      // Always compute a display-space crop; both iOS & Android plugins
      // take display coordinates and do the right transform internally.
      final displayCrop = VideoCropUtil.calculateDisplaySpaceCropRect(
        controller: controller,
        metadataRotation: metadataRotation,
      );
      cropRect = displayCrop;
    }

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

  // No extra helpers needed; crop mapping is centralized in VideoCropUtil
}
