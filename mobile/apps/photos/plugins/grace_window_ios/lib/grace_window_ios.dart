import "dart:io";

import "package:flutter/services.dart";

class GraceWindowIos {
  GraceWindowIos._();

  static const MethodChannel _methodChannel = MethodChannel(
    "io.ente.photos.grace_window_ios/methods",
  );

  static Future<void> beginGraceWindow(String name) async {
    if (!Platform.isIOS) {
      return;
    }

    await _methodChannel.invokeMethod("beginGraceWindow", {"name": name});
  }

  static Future<void> endGraceWindow() async {
    if (!Platform.isIOS) {
      return;
    }

    await _methodChannel.invokeMethod("endGraceWindow");
  }

  /// Waits for the native expiration handler to fire.
  /// Returns true if the grace window expired, false if it was ended normally.
  /// Best-effort same-process delivery via a solicited MethodChannel reply.
  /// The durable fallback is [consumeExpiredState] (backed by UserDefaults).
  static Future<bool> awaitExpiration() async {
    if (!Platform.isIOS) {
      return false;
    }

    return await _methodChannel.invokeMethod<bool>("awaitExpiration") ?? false;
  }

  static Future<bool> consumeExpiredState() async {
    if (!Platform.isIOS) {
      return false;
    }

    return await _methodChannel.invokeMethod<bool>(
          "consumeExpiredGraceWindowState",
        ) ??
        false;
  }
}
