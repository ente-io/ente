import "dart:io";

import "package:flutter/services.dart";
import "package:logging/logging.dart";

class InstallSourceService {
  InstallSourceService._privateConstructor();

  static final InstallSourceService instance =
      InstallSourceService._privateConstructor();

  static const _methodChannel = MethodChannel("io.ente.photos/install_source");
  static const _platformChannelTimeout = Duration(seconds: 3);

  final _logger = Logger("InstallSourceService");

  Future<void> logSource() => _logSource();

  Future<bool> hasInstallSource() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      return await _methodChannel
              .invokeMethod<bool>("hasInstallSource")
              .timeout(_platformChannelTimeout) ??
          false;
    } catch (e, s) {
      _logger.warning("Failed to check install source", e, s);
      return false;
    }
  }

  Future<void> _logSource() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final eventJson = await _methodChannel
          .invokeMethod<String>("logInstallSource")
          .timeout(_platformChannelTimeout);
      if (eventJson != null && eventJson.isNotEmpty) {
        _logger.info("InstallSourceEvent $eventJson");
      }
    } catch (e, s) {
      _logger.warning("Failed to log InstallSourceEvent", e, s);
    }
  }
}
