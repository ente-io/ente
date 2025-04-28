import "package:computer/computer.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_session.dart";

class IsolatedFfmpegService {
  static final Computer _computer = Computer.create();

  static void init() {
    _computer.turnOn(workersCount: 1);
  }

  static Future<FFmpegSession> runFfmpeg(String command) async {
    return _computer.compute<Map, FFmpegSession>(
      _ffmpegRun,
      param: {'command': command},
    );
  }

  static Future<FFmpegSession> _ffmpegRun(Map args) async {
    final command = args['command'] as String;
    final session = await FFmpegKit.execute(command);
    return session;
  }
}
