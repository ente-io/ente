import "dart:async" show unawaited;

import "package:wakelock_plus/wakelock_plus.dart";

class EnteWakeLock {
  bool _wakeLockEnabledHere = false;

  void enable() {
    WakelockPlus.enabled.then((value) {
      if (value == false) {
        WakelockPlus.enable();
        //wakeLockEnabledHere will not be set to true if wakeLock is already enabled from settings on iOS.
        //We shouldn't disable when video is not playing if it was enabled manually by the user from ente settings by user.
        _wakeLockEnabledHere = true;
      }
    });
  }

  void disable() {
    if (_wakeLockEnabledHere) {
      WakelockPlus.disable();
    }
  }

  void dispose() {
    if (_wakeLockEnabledHere) {
      unawaited(
        WakelockPlus.enabled.then((isEnabled) {
          isEnabled ? WakelockPlus.disable() : null;
        }),
      );
    }
  }

  static Future<void> toggle({required bool enable}) async {
    await WakelockPlus.toggle(enable: enable);
  }
}
