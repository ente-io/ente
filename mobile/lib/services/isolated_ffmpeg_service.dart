import "package:computer/computer.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_session.dart";
import "package:logging/logging.dart";

class IsolatedFfmpegService {
  static Computer? _computer;
  static final _logger = Logger("IsolatedFfmpegService");

  static Future<void> init() async {
    _computer = Computer.create();
    await _computer?.turnOn(workersCount: 1);
  }

  static Future<FFmpegSession> runFfmpeg(String command) async {
    if (_computer == null) {
      await init();
    }
    return await _computer!.compute<Map, FFmpegSession>(
      _ffmpegRun,
      param: {'command': command},
    ).onError((error, st) {
      _logger.warning("Error: $error");
      throw error!;
    });
  }

  static Future<FFmpegSession> _ffmpegRun(Map args) async {
    final command = args['command'] as String;
    final session = await FFmpegKit.execute(command);
    return session;
  }
}
