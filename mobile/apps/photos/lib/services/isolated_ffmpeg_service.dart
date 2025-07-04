import "dart:isolate" show Isolate;

import "package:computer/computer.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_session.dart";
import "package:flutter/services.dart"
    show RootIsolateToken, BackgroundIsolateBinaryMessenger;
import "package:logging/logging.dart";

class IsolatedFfmpegService {
  static Computer? _computer;
  static final _logger = Logger("IsolatedFfmpegService");

  static Future<void> init() async {
    _computer = Computer.create();
    await _computer?.turnOn(workersCount: 1);
  }

  static Future<dynamic> runFfmpeg(String command) async {
    // if (_computer == null) {
    //   await init();
    // }

    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    return await Isolate.spawn<(String, RootIsolateToken)>(
      _ffmpegRun,
      (command, rootIsolateToken),
    );
    // return await _computer!.compute<Map, FFmpegSession>(
    //   _ffmpegRun,
    //   param: {'command': command},
    // ).onError((error, st) {
    //   _logger.warning("Error: $error");
    //   throw error!;
    // });
  }

  static Future<FFmpegSession> _ffmpegRun(
    (String, RootIsolateToken) value,
  ) async {
    // BackgroundIsolateBinaryMessenger.ensureInitialized(value.$2);
    final session = await FFmpegKit.execute(value.$1);
    return session;
  }
}
