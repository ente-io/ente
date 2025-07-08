import "dart:async";

import "package:combine/combine.dart";
import "package:computer/computer.dart";
import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffprobe_kit.dart";
import "package:ffmpeg_kit_flutter/media_information.dart";
import "package:ffmpeg_kit_flutter/media_information_session.dart";
import "package:photos/utils/ffprobe_util.dart";

class IsolatedFfmpegService {
  static Computer? _computer;

  static Future<void> init() async {
    _computer = Computer.create();
    await _computer?.turnOn(workersCount: 1);
  }

  static Future<Map> runFfmpeg(String command) async {
    return await CombineWorker()
        .executeWithArg<Map, String>(_ffmpegRun, command);
  }

  static Future<Map> getVideoInfo(String file) async {
    return await CombineWorker()
        .executeWithArg<Map, String>(_getVideoProps, file);
  }
}

@pragma('vm:entry-point')
Future<Map> _getVideoProps(String filePath) async {
  final completer = Completer<MediaInformation?>();
  final session = await FFprobeKit.getMediaInformationAsync(
    filePath,
    (MediaInformationSession session) async {
      // This callback is called when the session is complete
      final mediaInfo = session.getMediaInformation();

      completer.complete(mediaInfo);
    },
    (log) {},
  );

  // Wait for the session to complete
  await session.getReturnCode();
  final mediaInfo = await completer.future;

  if (mediaInfo == null) {
    return {};
  }

  final metadata = await FFProbeUtil.getMetadata(mediaInfo);
  return metadata;
}

@pragma('vm:entry-point')
Future<Map> _ffmpegRun(String value) async {
  final session = await FFmpegKit.execute(value, true);
  final returnCode = (await session.getReturnCode())?.getValue();

  return {
    "returnCode": returnCode,
    "output": await session.getOutput(),
  };
}
