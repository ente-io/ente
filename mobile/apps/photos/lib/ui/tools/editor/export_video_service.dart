import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:video_editor/video_editor.dart';

class ExportService {
  static Future<void> dispose() async {
    final executions = await FFmpegKit.listSessions();
    if (executions.isNotEmpty) await FFmpegKit.cancel();
  }

  static Future<FFmpegSession> runFFmpegCommand(
    FFmpegVideoEditorExecute execute, {
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) {
    log('FFmpeg start process with command = ${execute.command}');
    return FFmpegKit.executeAsync(
      execute.command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(execute.outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}',
              ),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress,
    );
  }

  /// Export video using FFmpeg
  static Future<File> exportVideo({
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

    await runFFmpegCommand(
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
}
