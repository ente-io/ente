import "dart:async";
import "dart:isolate";

import "package:ffmpeg_kit_flutter/ffmpeg_kit.dart";
import "package:ffmpeg_kit_flutter/ffprobe_kit.dart";
import "package:flutter/services.dart";
import "package:photos/utils/ffprobe_util.dart";

class IsolatedFfmpegService {
  static Future<Map> runFfmpeg(String command) async {
    final rootIsolateToken = RootIsolateToken.instance!;
    return await Isolate.run<Map>(() => _ffmpegRun(command, rootIsolateToken));
  }

  static Future<Map> getVideoInfo(String file) async {
    final rootIsolateToken = RootIsolateToken.instance!;
    return await Isolate.run<Map>(() => _getVideoProps(file, rootIsolateToken));
  }
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
  };
}
