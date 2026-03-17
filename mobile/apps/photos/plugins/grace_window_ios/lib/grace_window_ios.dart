import "dart:async";
import "dart:io";

import "package:flutter/services.dart";

class GraceWindowIos {
  GraceWindowIos._();

  static const MethodChannel _methodChannel = MethodChannel(
    "io.ente.photos.grace_window_ios/methods",
  );
  static const EventChannel _eventChannel = EventChannel(
    "io.ente.photos.grace_window_ios/events",
  );

  static Stream<void>? _expirationStream;

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

  static Stream<void> get onGraceWindowExpired {
    if (!Platform.isIOS) {
      return const Stream<void>.empty();
    }

    return _expirationStream ??= _eventChannel.receiveBroadcastStream().map(
          (_) {},
        );
  }
}
