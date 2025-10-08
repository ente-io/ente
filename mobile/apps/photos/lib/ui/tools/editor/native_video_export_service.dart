import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:native_video_editor/native_video_editor.dart';
import 'package:video_editor/video_editor.dart';
import 'package:photos/ui/tools/editor/export_video_service.dart';
import 'package:photos/ui/tools/editor/video_crop_util.dart';

class DebugExportSummary {
  DebugExportSummary({
    required this.metadataRotation,
    required this.videoSize,
    required this.trimStart,
    required this.trimEnd,
    required this.nativeRotateDegrees,
    required this.nativeDisplayCrop,
    required this.nativeFileCrop,
    required this.nativeOutputSize,
    required this.ffmpegFileCrop,
    required this.ffmpegCropFilter,
    required this.ffmpegNoAutoRotate,
  });

  final int metadataRotation;
  final Size videoSize;
  final Duration? trimStart;
  final Duration? trimEnd;
  final int? nativeRotateDegrees;
  final Rect? nativeDisplayCrop;
  final CropCalculation? nativeFileCrop;
  final Size? nativeOutputSize;
  final CropCalculation? ffmpegFileCrop;
  final String? ffmpegCropFilter;
  final bool ffmpegNoAutoRotate;
}

/// Service that uses native video editing operations when possible
/// Falls back to FFmpeg for operations that require re-encoding
class NativeVideoExportService {
  static final _logger = Logger('NativeVideoExportService');
  static const Duration _nativeFallbackThreshold = Duration(seconds: 3);

  static Future<DebugExportSummary> buildDebugSummary({
    required VideoEditorController controller,
    required int metadataRotation,
  }) async {
    final videoSize = controller.video.value.size;
    final Duration? trimStart =
        controller.isTrimmed ? controller.startTrim : null;
    final Duration? trimEnd = controller.isTrimmed ? controller.endTrim : null;
    final int? nativeRotateDegrees =
        controller.rotation != 0 ? controller.rotation : null;

    Rect? nativeDisplayCrop;
    CropCalculation? nativeFileCrop;
    Size? nativeOutputSize;
    CropCalculation? ffmpegFileCrop;

    final needsCrop = controller.minCrop != Offset.zero ||
        controller.maxCrop != const Offset(1.0, 1.0);

    if (needsCrop) {
      nativeDisplayCrop = VideoCropUtil.calculateDisplaySpaceCropRect(
        controller: controller,
        metadataRotation: metadataRotation,
      );
      try {
        nativeFileCrop = VideoCropUtil.calculateFileSpaceCrop(
          controller: controller,
          metadataRotation: metadataRotation,
        );
      } catch (_) {
        nativeFileCrop = null;
      }

      if (nativeFileCrop != null) {
        nativeOutputSize = Size(
          nativeFileCrop.width.toDouble(),
          nativeFileCrop.height.toDouble(),
        );
        if (nativeRotateDegrees != null && nativeRotateDegrees % 180 != 0) {
          nativeOutputSize = Size(
            nativeOutputSize.height,
            nativeOutputSize.width,
          );
        }
      }

      try {
        ffmpegFileCrop = VideoCropUtil.calculateFileSpaceCrop(
          controller: controller,
          metadataRotation: metadataRotation,
        );
      } catch (_) {
        ffmpegFileCrop = null;
      }
    }

    String? ffmpegCropFilter;
    if (ffmpegFileCrop != null) {
      ffmpegCropFilter = ffmpegFileCrop.toFFmpegFilter();
    }

    return DebugExportSummary(
      metadataRotation: metadataRotation,
      videoSize: videoSize,
      trimStart: trimStart,
      trimEnd: trimEnd,
      nativeRotateDegrees: nativeRotateDegrees,
      nativeDisplayCrop: nativeDisplayCrop,
      nativeFileCrop: nativeFileCrop,
      nativeOutputSize: nativeOutputSize,
      ffmpegFileCrop: ffmpegFileCrop,
      ffmpegCropFilter: ffmpegCropFilter,
      ffmpegNoAutoRotate: metadataRotation != 0,
    );
  }

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

      // If native export fails quickly, attempt FFmpeg fallback automatically
      if (elapsed <= _nativeFallbackThreshold) {
        _logger.warning(
          'Native export failed within ${elapsed.inMilliseconds}ms; falling back to FFmpeg.',
        );
        return await ExportService.exportVideo(
          controller: controller,
          outputPath: outputPath,
          onProgress: onProgress,
          onError: onError,
        );
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
    // Use the combined native path only when needed; otherwise do a fast copy.
    // Note: despite legacy comments, Android cropping is supported via Media3
    // Transformer, so we keep native for crop/trim/rotate combinations.
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
      if (displayCrop.width <= 0 || displayCrop.height <= 0) {
        throw ArgumentError('Invalid crop rectangle computed: $displayCrop');
      }
      cropRect = displayCrop;
    }

    if (cropRect != null && _logger.isLoggable(Level.FINE)) {
      _logger.fine(
        'Native export cropRect=$cropRect videoSize=${controller.video.value.size} '
        'metadataRotation=$metadataRotation',
      );
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
