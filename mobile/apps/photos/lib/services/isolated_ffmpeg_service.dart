import "dart:async";
import "dart:isolate";

import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffprobe_kit.dart";
import "package:flutter/services.dart";
import "package:photos/utils/ffprobe_util.dart";

class IsolatedFfmpegService {
  IsolatedFfmpegService._privateConstructor();

  static final IsolatedFfmpegService instance =
      IsolatedFfmpegService._privateConstructor();

  /// Legacy helper for FFmpeg without session tracking.
  Future<Map> runFfmpeg(String command) async {
    final rootIsolateToken = RootIsolateToken.instance!;
    return await Isolate.run<Map>(() => _ffmpegRun(command, rootIsolateToken));
  }

  /// Run FFmpeg in an isolate with session ID callback for cancellation support.
  /// The [onSessionStarted] callback is called immediately when FFmpeg starts,
  /// allowing the caller to track the session ID for potential cancellation.
  Future<Map> runFfmpegWithSessionTracking(
    String command, {
    required void Function(int sessionId) onSessionStarted,
  }) async {
    final rootIsolateToken = RootIsolateToken.instance!;
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _ffmpegRunWithPort,
      _FfmpegPortParams(
        command: command,
        sendPort: receivePort.sendPort,
        rootIsolateToken: rootIsolateToken,
      ),
    );

    final completer = Completer<Map>();

    receivePort.listen((message) {
      if (message is _SessionStartedMessage) {
        // Session ID received - notify caller for tracking
        onSessionStarted(message.sessionId);
      } else if (message is _FfmpegResultMessage) {
        // FFmpeg completed - return result and close port
        if (!completer.isCompleted) {
          completer.complete(message.result);
        }
        receivePort.close();
      }
    });

    return completer.future;
  }

  Future<Map> getVideoInfo(String file) async {
    final rootIsolateToken = RootIsolateToken.instance!;
    return await Isolate.run<Map>(() => _getVideoProps(file, rootIsolateToken));
  }
}

/// Parameters for FFmpeg execution with port communication
class _FfmpegPortParams {
  final String command;
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;

  _FfmpegPortParams({
    required this.command,
    required this.sendPort,
    required this.rootIsolateToken,
  });
}

/// Message sent when FFmpeg session starts
class _SessionStartedMessage {
  final int sessionId;
  _SessionStartedMessage(this.sessionId);
}

/// Message sent when FFmpeg completes
class _FfmpegResultMessage {
  final Map result;
  _FfmpegResultMessage(this.result);
}

@pragma('vm:entry-point')
Future<Map> _getVideoProps(
  String filePath,
  RootIsolateToken rootIsolateToken,
) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  final session = await FFprobeKit.getMediaInformation(filePath);
  final mediaInfo = session.getMediaInformation();

  if (mediaInfo == null) {
    return {};
  }

  final metadata = await FFProbeUtil.getMetadata(mediaInfo);
  return metadata;
}

@pragma('vm:entry-point')
Future<Map> _ffmpegRun(String value, RootIsolateToken rootIsolateToken) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  final session = await FFmpegKit.execute(value, true);
  final returnCode = await session.getReturnCode();
  final output = await session.getOutput();

  return {
    "returnCode": returnCode?.getValue(),
    "output": output,
    "sessionId": session.getSessionId(),
  };
}

/// FFmpeg execution with port-based session ID communication.
/// Sends session ID immediately when FFmpeg starts, then sends result when done.
@pragma('vm:entry-point')
Future<void> _ffmpegRunWithPort(_FfmpegPortParams params) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);

  final completer = Completer<Map>();

  // Use executeAsync to get session ID immediately
  final session = await FFmpegKit.executeAsync(
    params.command,
    (completedSession) async {
      final returnCode = await completedSession.getReturnCode();
      final output = await completedSession.getOutput();

      completer.complete({
        "returnCode": returnCode?.getValue(),
        "output": output,
        "sessionId": completedSession.getSessionId(),
      });
    },
  );

  // Send session ID immediately for tracking/cancellation
  final sessionId = session.getSessionId();
  if (sessionId != null) {
    params.sendPort.send(_SessionStartedMessage(sessionId));
  }

  // Wait for FFmpeg to complete
  final result = await completer.future;

  // Send result back to main isolate
  params.sendPort.send(_FfmpegResultMessage(result));
}
