import 'dart:developer';
import 'dart:io';

import 'package:native_video_editor/native_video_editor.dart';
import 'package:photos/ui/tools/editor/export_video_service.dart';
import 'package:video_editor/video_editor.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';

/// Service that uses native video editing operations when possible
/// Falls back to FFmpeg for operations that require re-encoding
class NativeVideoExportService {
  static final _logger = log;

  /// Export video using native operations when possible
  static Future<File> exportVideo({
    required VideoEditorController controller,
    required String outputPath,
    void Function(double)? onProgress,
    void Function(Object, StackTrace)? onError,
  }) async {
    try {
      final inputPath = controller.file.path;

      // Analyze what operations are needed
      final needsTrim = controller.isTrimmed;
      final needsRotation = controller.rotation != 0;
      final needsCrop = controller.isCropped;

      // Determine if we can use native operations
      final canUseNative = _canUseNativeOperations(
        needsTrim: needsTrim,
        needsRotation: needsRotation,
        needsCrop: needsCrop,
        controller: controller,
      );

      if (canUseNative) {
        _logger('Using native video operations for export');

        // Use native operations
        final result = await _performNativeOperations(
          inputPath: inputPath,
          outputPath: outputPath,
          controller: controller,
          onProgress: onProgress,
        );

        if (!result.isReEncoded) {
          _logger('Video exported without re-encoding in ${result.processingTime?.inMilliseconds}ms');
        } else {
          _logger('Video exported with re-encoding in ${result.processingTime?.inMilliseconds}ms');
        }

        return File(result.outputPath);
      } else {
        _logger('Falling back to FFmpeg for complex operations');

        // Fallback to FFmpeg for complex operations
        return await _exportWithFFmpeg(
          controller: controller,
          outputPath: outputPath,
          onProgress: onProgress,
          onError: onError,
        );
      }
    } catch (e, s) {
      _logger('Error in native export, falling back to FFmpeg: $e');

      // If native export fails, fallback to FFmpeg
      return await _exportWithFFmpeg(
        controller: controller,
        outputPath: outputPath,
        onProgress: onProgress,
        onError: onError,
      );
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

    // If we need complex crop operations, use FFmpeg
    if (needsCrop) {
      // For now, we'll use FFmpeg for all crop operations
      // until we implement efficient native cropping
      return false;
    }

    // Check if we're applying filters or other effects that require FFmpeg
    if (controller.videoEffects?.isNotEmpty ?? false) {
      return false;
    }

    return true;
  }

  /// Perform native video operations
  static Future<VideoEditResult> _performNativeOperations({
    required String inputPath,
    required String outputPath,
    required VideoEditorController controller,
    void Function(double)? onProgress,
  }) async {
    // If we need multiple operations, use the combined processVideo method
    if (controller.isTrimmed || controller.rotation != 0) {
      Duration? trimStart;
      Duration? trimEnd;
      int? rotateDegrees;

      if (controller.isTrimmed) {
        trimStart = controller.startTrim;
        trimEnd = controller.endTrim;
      }

      if (controller.rotation != 0) {
        rotateDegrees = controller.rotation;
      }

      return await NativeVideoEditor.processVideo(
        inputPath: inputPath,
        outputPath: outputPath,
        trimStart: trimStart,
        trimEnd: trimEnd,
        rotateDegrees: rotateDegrees,
      );
    }

    // If no operations needed, just copy the file
    await File(inputPath).copy(outputPath);
    return VideoEditResult(
      outputPath: outputPath,
      isReEncoded: false,
      processingTime: Duration.zero,
    );
  }

  /// Fallback to FFmpeg for complex operations
  static Future<File> _exportWithFFmpeg({
    required VideoEditorController controller,
    required String outputPath,
    void Function(double)? onProgress,
    void Function(Object, StackTrace)? onError,
  }) async {
    final config = VideoFFmpegVideoEditorConfig(
      controller,
      format: VideoExportFormat.mp4,
      commandBuilder: (config, videoPath, outputPath) {
        final List<String> filters = config.getExportFilters();

        final String startTrimCmd = "-ss ${controller.startTrim}";
        final String toTrimCmd = "-t ${controller.trimmedDuration}";

        // Use hardware acceleration if available
        String hwAccel = "";
        if (Platform.isIOS) {
          hwAccel = "-hwaccel videotoolbox";
        } else if (Platform.isAndroid) {
          hwAccel = "-hwaccel mediacodec";
        }

        return '$hwAccel $startTrimCmd -i $videoPath $toTrimCmd ${config.filtersCmd(filters)} -c:v libx264 -preset ultrafast -c:a aac $outputPath';
      },
    );

    final completer = Completer<File>();

    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (Statistics stats) {
        if (onProgress != null) {
          final progress = config.getFFmpegProgress(stats.getTime().toInt());
          onProgress(progress);
        }
      },
      onError: onError,
      onCompleted: (File file) {
        completer.complete(file);
      },
    );

    return completer.future;
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

      // Also cancel FFmpeg if it's running
      await ExportService.dispose();
    } catch (e) {
      _logger('Error cancelling export: $e');
    }
  }
}

// Add missing import
import 'dart:async';