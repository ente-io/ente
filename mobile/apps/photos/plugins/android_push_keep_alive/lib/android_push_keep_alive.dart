import 'dart:io';

import 'package:flutter/services.dart';

class AndroidPushKeepAlive {
  static const String channelName =
      "android_push_keep_alive/background_keep_alive";
  static const String methodIsEnabled = "isPushKeepAliveEnabled";
  static const String methodStart = "startPushKeepAlive";
  static const String methodStop = "stopPushKeepAlive";

  static const MethodChannel _channel = MethodChannel(channelName);

  Future<bool> isEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    return await _channel.invokeMethod<bool>(methodIsEnabled) ?? false;
  }

  Future<bool> start() async {
    if (!Platform.isAndroid) {
      return false;
    }

    await _channel.invokeMethod(methodStart);
    return true;
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod(methodStop);
  }
}
