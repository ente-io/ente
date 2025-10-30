import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:native_video_editor/native_video_editor.dart';
import 'package:photos/ui/tools/editor/export_video_service.dart';
import 'package:photos/ui/tools/editor/video_crop_util.dart';
import 'package:video_editor/video_editor.dart';

class DebugExportSummary {
  DebugExportSummary({
    required this.videoSize,
    required this.trimStart,
    required this.trimEnd,
    required this.nativeRotateDegrees,
    required this.nativeDisplayCrop,
    required this.nativeFileCrop,
    required this.nativeOutputSize,
    required this.ffmpegFileCrop,
    required this.ffmpegCropFilter,
    required this.ffmpegCommand,
  });

  final Size videoSize;
  final Duration? trimStart;
  final Duration? trimEnd;
  final int? nativeRotateDegrees;
  final Rect? nativeDisplayCrop;
  final CropCalculation? nativeFileCrop;
  final Size? nativeOutputSize;
  final CropCalculation? ffmpegFileCrop;
  final String? ffmpegCropFilter;
  final String? ffmpegCommand;
}

/// Service that uses native video editing operations when possible
/// Falls back to FFmpeg for operations that require re-encoding
class NativeVideoExportService {
  static const Duration _nativeFallbackThreshold = Duration(seconds: 3);

  static Future<DebugExportSummary> buildDebugSummary({
    required VideoEditorController controller,
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
      );
      try {
        nativeFileCrop = VideoCropUtil.calculateFileSpaceCrop(
          controller: controller,
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
        );
      } catch (_) {
        ffmpegFileCrop = null;
      }
    }

    String? ffmpegCropFilter;
    if (ffmpegFileCrop != null) {
      ffmpegCropFilter = ffmpegFileCrop.toFFmpegFilter();
    }

    // Build approximate FFmpeg command for debugging
    String? ffmpegCommand;
    if (ffmpegCropFilter != null || trimStart != null || trimEnd != null) {
      final List<String> cmdParts = ['ffmpeg -i input.mp4'];

      if (trimStart != null || trimEnd != null) {
        final ss = trimStart?.inMilliseconds ?? 0;
        final to =
            trimEnd?.inMilliseconds ?? controller.videoDuration.inMilliseconds;
        cmdParts.add('-ss ${ss}ms -to ${to}ms');
      }

      final vfFilters = <String>[];
      if (ffmpegCropFilter != null) {
        vfFilters.add(ffmpegCropFilter);
      }
      vfFilters.add('setpts=PTS-STARTPTS');

      cmdParts.add('-vf "${vfFilters.join(',')}"');
      cmdParts.add('-c:v libx264 -preset ultrafast -c:a copy output.mp4');

      ffmpegCommand = cmdParts.join(' ');
    }

    return DebugExportSummary(
      videoSize: videoSize,
      trimStart: trimStart,
      trimEnd: trimEnd,
      nativeRotateDegrees: nativeRotateDegrees,
      nativeDisplayCrop: nativeDisplayCrop,
      nativeFileCrop: nativeFileCrop,
      nativeOutputSize: nativeOutputSize,
      ffmpegFileCrop: ffmpegFileCrop,
      ffmpegCropFilter: ffmpegCropFilter,
      ffmpegCommand: ffmpegCommand,
    );
  }

  /// Export video using native operations
  ///
  /// [allowFfmpegFallback] - If true (default), automatically falls back to
  /// FFmpeg if native export fails quickly. Set to false to test native-only
  /// processing (useful for integration tests).
  static Future<File> exportVideo({
    required VideoEditorController controller,
    required String outputPath,
    void Function(double)? onProgress,
    void Function(Object, StackTrace)? onError,
    bool allowFfmpegFallback = true,
  }) async {
    final startTime = DateTime.now();
    try {
      final inputPath = controller.file.path;

      // Always use the unified native operations path
      final result = await _performNativeOperations(
        inputPath: inputPath,
        outputPath: outputPath,
        controller: controller,
        onProgress: onProgress,
      );

      return File(result.outputPath);
    } catch (error, stackTrace) {
      final elapsed = DateTime.now().difference(startTime);

      if (onError != null) {
        onError(error, stackTrace);
      }

      // If native export fails quickly, attempt FFmpeg fallback automatically
      // (only if fallback is enabled)
      if (allowFfmpegFallback && elapsed <= _nativeFallbackThreshold) {
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
      );
      if (displayCrop.width <= 0 || displayCrop.height <= 0) {
        throw ArgumentError('Invalid crop rectangle computed: $displayCrop');
      }
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
