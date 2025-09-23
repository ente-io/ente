import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/session_state.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:logging/logging.dart';
import 'package:video_editor/video_editor.dart';

class ExportService {
  static final _logger = Logger('ExportService');

  static Future<void> dispose() async {
    _logger.info('[FFmpeg] Disposing export service');
    final executions = await FFmpegKit.listSessions();
    _logger.info('[FFmpeg] Found ${executions.length} active sessions');
    if (executions.isNotEmpty) {
      _logger.info('[FFmpeg] Cancelling all sessions');
      await FFmpegKit.cancel();
    }
  }

  static Future<void> runFFmpegCommand(
    FFmpegVideoEditorExecute execute, {
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) async {
    log('FFmpeg start process with command = ${execute.command}');

    final completer = Completer<void>();
    FFmpegSession? activeSession;

    try {
      // Run FFmpeg with async callbacks
      activeSession = await FFmpegKit.executeAsync(
        execute.command,
        (session) async {
          // Session complete callback
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();

          if (returnCode != null && ReturnCode.isSuccess(returnCode)) {
            final outputFile = File(execute.outputPath);

            if (!outputFile.existsSync()) {
              _logger.warning(
                'Output file does not exist at ${execute.outputPath}',
              );
            }

            onCompleted(outputFile);
          } else {
            final errorCode = returnCode?.getValue() ?? -1;
            _logger.severe('FFmpeg process failed with return code $errorCode');

            final error = Exception(
              'FFmpeg process exited with return code $errorCode.\n$output',
            );

            if (onError != null) {
              onError(error, StackTrace.current);
            }
          }

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        null, // No log callback
        (statistics) {
          // Statistics callback for progress
          if (onProgress != null) {
            onProgress(statistics);
          }
        },
      );

      // Poll session state to ensure we wait for completion
      bool callbackTriggered = false;
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (activeSession != null) {
          final state = await activeSession.getState();
          final statisticsList = await activeSession.getStatistics();

          if (statisticsList != null &&
              statisticsList.isNotEmpty &&
              onProgress != null) {
            final statistics = statisticsList.last;
            onProgress(statistics);
          }

          if (state == SessionState.completed) {
            timer.cancel();

            // If callback hasn't been triggered yet, do it manually
            if (!callbackTriggered && !completer.isCompleted) {
              callbackTriggered = true;

              // Get the return code and handle completion
              final returnCode = await activeSession.getReturnCode();

              if (returnCode != null && ReturnCode.isSuccess(returnCode)) {
                final outputFile = File(execute.outputPath);

                if (!outputFile.existsSync()) {
                  _logger.warning(
                    'Output file does not exist at ${execute.outputPath}',
                  );
                }

                onCompleted(outputFile);
              } else {
                final errorCode = returnCode?.getValue() ?? -1;
                _logger.severe(
                  'FFmpeg process failed with return code $errorCode',
                );

                final error = Exception(
                  'FFmpeg process exited with return code $errorCode',
                );

                if (onError != null) {
                  onError(error, StackTrace.current);
                }
              }

              completer.complete();
            }
          } else if (state == SessionState.failed) {
            timer.cancel();
            if (!completer.isCompleted) {
              final error = Exception('FFmpeg process failed');
              if (onError != null) {
                onError(error, StackTrace.current);
              }
              completer.complete();
            }
          }
        }
      });

      // Wait for the session to complete
      await completer.future;
    } catch (e, stackTrace) {
      _logger.severe('FFmpeg execution error: $e');
      if (activeSession != null) {
        await FFmpegKit.cancel(activeSession.getSessionId());
      }
      if (onError != null) {
        onError(e, stackTrace);
      } else {
        rethrow;
      }
    }
  }
}
