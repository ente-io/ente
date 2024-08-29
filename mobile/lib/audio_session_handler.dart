import "package:flutter/services.dart";
import "package:logging/logging.dart";

class AudioSessionHandler {
  static final _logger = Logger("AudioSessionHandler");
  static const MethodChannel _channel =
      MethodChannel('io.ente.frame/audio_session');

  static Future<void> setAudioSessionCategory() async {
    try {
      await _channel.invokeMethod('setAudioSessionCategory');
    } on PlatformException catch (e) {
      _logger.warning("Failed to set audio session category: '${e.message}'.");
    }
  }
}
