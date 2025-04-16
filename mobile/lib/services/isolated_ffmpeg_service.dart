import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_session.dart";

class IsolatedFfmpegService {
  static Future<FFmpegSession> ffmpegRun(Map args) async {
    final command = args['command'] as String;

    final session = await FFmpegKit.execute(command);

    return session;
  }
}
