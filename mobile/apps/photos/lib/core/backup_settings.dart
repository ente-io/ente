import "package:shared_preferences/shared_preferences.dart";

class BackupSettings {
  BackupSettings(this._preferences);

  static const _keyShouldBackupOverMobileData =
      "should_backup_over_mobile_data";
  static const _keyShouldBackupVideos = "should_backup_videos";

  final SharedPreferences _preferences;

  bool shouldBackupOverMobileData() {
    if (_preferences.containsKey(_keyShouldBackupOverMobileData)) {
      return _preferences.getBool(_keyShouldBackupOverMobileData)!;
    } else {
      return false;
    }
  }

  Future<void> setBackupOverMobileData(bool value) async {
    await _preferences.setBool(_keyShouldBackupOverMobileData, value);
  }

  bool shouldBackupVideos() {
    if (_preferences.containsKey(_keyShouldBackupVideos)) {
      return _preferences.getBool(_keyShouldBackupVideos)!;
    } else {
      return true;
    }
  }

  Future<void> setShouldBackupVideos(bool value) async {
    await _preferences.setBool(_keyShouldBackupVideos, value);
  }
}
