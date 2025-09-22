import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:flutter/services.dart';
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
    _logger.info('[FFmpeg] Starting FFmpeg process');
    _logger.info('[FFmpeg] Command: ${execute.command}');
    _logger.info('[FFmpeg] Output path: ${execute.outputPath}');
    log('FFmpeg start process with command = ${execute.command}');

    try {
      // Use a dedicated isolate for video export with progress tracking
      _logger.info('[FFmpeg] Executing FFmpeg command in video export isolate');

      final receivePort = ReceivePort();
      final rootIsolateToken = RootIsolateToken.instance!;

      final isolate = await Isolate.spawn(
        _videoExportIsolate,
        _VideoExportParams(
          command: execute.command,
          outputPath: execute.outputPath,
          sendPort: receivePort.sendPort,
          rootIsolateToken: rootIsolateToken,
        ),
      );

      // Listen for messages from the isolate
      await for (final message in receivePort) {
        if (message is Map) {
          if (message['type'] == 'progress') {
            // Parse progress from FFmpeg output if available
            final int? time = message['time'];
            if (time != null && onProgress != null) {
              // Create a mock Statistics object with the time
              _logger.info('[FFmpeg] Progress: ${time}ms');
              // Note: We can't create real Statistics objects, so we'll skip progress for now
            }
          } else if (message['type'] == 'complete') {
            final returnCode = message['returnCode'];
            final output = message['output'] ?? '';

            _logger.info('[FFmpeg] Session completed with return code: $returnCode');

            if (returnCode == 0) {
              _logger.info('[FFmpeg] Success! Creating output file');
              final outputFile = File(execute.outputPath);

              if (!outputFile.existsSync()) {
                _logger.warning('[FFmpeg] Output file does not exist at ${execute.outputPath}');
              } else {
                _logger.info(
                  '[FFmpeg] Output file size: ${outputFile.lengthSync()} bytes',
                );
              }

              onCompleted(outputFile);
              _logger.info('[FFmpeg] Export completed successfully');
            } else {
              _logger.severe('[FFmpeg] Failed with code: $returnCode');
              _logger.severe('[FFmpeg] Output: $output');

              final error = Exception(
                'FFmpeg process exited with return code $returnCode.\n$output',
              );

              if (onError != null) {
                onError(error, StackTrace.current);
              }
            }

            // Clean up
            receivePort.close();
            isolate.kill();
            break;
          } else if (message['type'] == 'error') {
            final error = Exception(message['error'] ?? 'Unknown error in isolate');
            _logger.severe('[FFmpeg] Error in isolate: ${message['error']}');

            if (onError != null) {
              onError(error, StackTrace.current);
            }

            // Clean up
            receivePort.close();
            isolate.kill();
            break;
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('[FFmpeg] Exception during execution: $e', e, stackTrace);
      if (onError != null) {
        onError(e, stackTrace);
      } else {
        rethrow;
      }
    }
  }
}

// Parameters for the video export isolate
class _VideoExportParams {
  final String command;
  final String outputPath;
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;

  _VideoExportParams({
    required this.command,
    required this.outputPath,
    required this.sendPort,
    required this.rootIsolateToken,
  });
}

// Isolate function for video export
@pragma('vm:entry-point')
Future<void> _videoExportIsolate(_VideoExportParams params) async {
  try {
    // Initialize binary messenger for FFmpeg
    BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);

    // Use synchronous execution in isolate since async callbacks don't work with the custom fork
    final session = await FFmpegKit.execute(params.command, true);

    final returnCode = await session.getReturnCode();
    final output = await session.getOutput();

    params.sendPort.send({
      'type': 'complete',
      'returnCode': returnCode?.getValue() ?? -1,
      'output': output,
    });
  } catch (e) {
    params.sendPort.send({
      'type': 'error',
      'error': e.toString(),
    });
  }
}
