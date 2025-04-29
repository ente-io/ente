import "package:shared_preferences/shared_preferences.dart";
import "package:wakelock_plus/wakelock_plus.dart";

enum WakeLockFor {
  videoPlayback,
  fasterBackupsOniOSByKeepingScreenAwake,
  machineLearningSettingsScreen,
  handlingMediaKitEdgeCase,
}

/// Use this wrapper to use wakelock. This class makes sure that the wakelock
/// setting across sessions if set is respected when wakelock is updated for
/// other non across session purposes.
/// Only place where this wrapper is not used for accessing wakelock APIs is
/// in media_kit package.
class EnteWakeLockService {
  static const String kKeepAppAwakeAcrossSessions =
      "keepAppAwakeAcrossSessions";

  EnteWakeLockService._privateConstructor();

  static final EnteWakeLockService instance =
      EnteWakeLockService._privateConstructor();

  late SharedPreferences _prefs;

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    if (_prefs.getBool(kKeepAppAwakeAcrossSessions) ?? false) {
      WakelockPlus.enable();
    }
  }

  void updateWakeLock({
    required bool enable,
    required WakeLockFor wakeLockFor,
  }) {
    if (wakeLockFor == WakeLockFor.fasterBackupsOniOSByKeepingScreenAwake ||
        wakeLockFor == WakeLockFor.handlingMediaKitEdgeCase) {
      WakelockPlus.toggle(enable: enable);
      _prefs.setBool(kKeepAppAwakeAcrossSessions, enable);
    } else {
      if (!shouldKeepAppAwakeAcrossSessions) {
        WakelockPlus.toggle(enable: enable);
      }
    }
  }

  bool get shouldKeepAppAwakeAcrossSessions =>
      _prefs.getBool(kKeepAppAwakeAcrossSessions) ?? false;
}
