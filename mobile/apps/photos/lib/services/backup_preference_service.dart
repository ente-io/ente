import 'dart:async';

import 'package:ente_feature_flag/ente_feature_flag.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupPreferenceService {
  BackupPreferenceService(
    this._prefs,
    this._flagService,
  );

  static const String _keyHasSelectedAnyBackupFolder =
      "has_selected_any_folder_for_backup";
  static const String _keyHasSelectedAllFoldersForBackup =
      "has_selected_all_folders_for_backup";
  static const String _keyShouldAutoSelectFolders =
      "has_manual_backup_folder_selection";
  static const String _keyOnboardingPermissionSkipped =
      "onboarding_permission_skipped";
  static const String _keyOnlyNewSinceEpoch = "backup_only_new_since_epoch";

  final SharedPreferences _prefs;
  final FlagService _flagService;

  final Logger _logger = Logger('BackupPreferenceService');

  bool get hasSelectedAnyBackupFolder =>
      _prefs.getBool(_keyHasSelectedAnyBackupFolder) ?? false;

  Future<void> setHasSelectedAnyBackupFolder(bool value) async {
    await _prefs.setBool(_keyHasSelectedAnyBackupFolder, value);
  }

  bool get hasSelectedAllFoldersForBackup =>
      _prefs.getBool(_keyHasSelectedAllFoldersForBackup) ?? false;

  Future<void> setSelectAllFoldersForBackup(bool value) async {
    await _prefs.setBool(_keyHasSelectedAllFoldersForBackup, value);
  }

  bool get hasManualFolderSelection =>
      _prefs.getBool(_keyShouldAutoSelectFolders) ?? false;

  Future<void> setHasManualFolderSelection(bool value) async {
    await _prefs.setBool(_keyShouldAutoSelectFolders, value);
  }

  bool get hasSkippedOnboardingPermission {
    if (!_flagService.enableOnlyBackupFuturePhotos) {
      return false;
    }
    return _prefs.getBool(_keyOnboardingPermissionSkipped) ?? false;
  }

  Future<void> setOnboardingPermissionSkipped(bool value) async {
    await _prefs.setBool(_keyOnboardingPermissionSkipped, value);
  }

  int? get onlyNewSinceEpoch {
    if (!_flagService.enableOnlyBackupFuturePhotos) {
      return null;
    }
    return _prefs.getInt(_keyOnlyNewSinceEpoch);
  }

  bool get isOnlyNewBackupEnabled {
    if (!_flagService.enableOnlyBackupFuturePhotos) {
      return false;
    }
    return _prefs.containsKey(_keyOnlyNewSinceEpoch);
  }

  Future<void> setOnlyNewSinceEpoch(int timestamp) async {
    if (timestamp <= 0) {
      _logger.severe("Invalid timestamp for only-new backup: $timestamp");
      return;
    }
    await _applyOnlyNewThreshold(timestamp);
  }

  Future<void> setOnlyNewSinceSevenDaysAgo() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final threshold = DateTime(
      sevenDaysAgo.year,
      sevenDaysAgo.month,
      sevenDaysAgo.day,
    ).microsecondsSinceEpoch;
    if (threshold <= 0) {
      _logger.severe("Invalid timestamp for only-new backup: $threshold");
      return;
    }
    _logger.info(
      "Setting only-new backup threshold to $threshold (7 days ago at 12 AM)",
    );
    await _applyOnlyNewThreshold(threshold);
    await _ensureDefaultFolderSelection();
  }

  Future<void> setOnlyNewSinceNow() async {
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now <= 0) {
      _logger.severe("Invalid timestamp for only-new backup: $now");
      return;
    }
    _logger.info("Setting only-new backup threshold to $now");
    await _applyOnlyNewThreshold(now);
  }

  Future<void> clearOnlyNewSinceEpoch() async {
    await _prefs.remove(_keyOnlyNewSinceEpoch);
  }

  /// Applies the only-new backup threshold by saving it to preferences and
  /// triggering cleanup of old pending uploads in the background.
  /// The cleanup is fire-and-forget to avoid blocking the UI during
  /// onboarding or settings toggle.
  Future<void> _applyOnlyNewThreshold(int timestamp) async {
    await _prefs.setInt(_keyOnlyNewSinceEpoch, timestamp);
    // Fire-and-forget: run cleanup in background to avoid blocking UI.
    // The actual filtering will happen during sync/upload anyway.
    unawaited(
      RemoteSyncService.instance
          .handleOnlyNewBackupThresholdUpdated(timestamp)
          .catchError((e, s) {
        _logger.warning(
          'Background cleanup after only-new threshold update failed',
          e,
          s,
        );
      }),
    );
  }

  Future<void> _ensureDefaultFolderSelection() async {
    if (hasManualFolderSelection || hasSelectedAnyBackupFolder) {
      return;
    }
    try {
      await _setAllFoldersShouldBackup(true);
      await setSelectAllFoldersForBackup(true);
      await setHasSelectedAnyBackupFolder(true);
      if (hasSkippedOnboardingPermission) {
        await setOnboardingPermissionSkipped(false);
      }
      _logger.info('Auto-selected all folders for backup');
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to auto-select all folders for backup',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _setAllFoldersShouldBackup(bool shouldBackup) async {
    final List<DeviceCollection> deviceCollections =
        await FilesDB.instance.getDeviceCollections();
    if (deviceCollections.isEmpty) {
      return;
    }
    final Map<String, bool> updateMap = {
      for (final collection in deviceCollections) collection.id: shouldBackup,
    };
    if (updateMap.isEmpty) {
      return;
    }
    await RemoteSyncService.instance.updateDeviceFolderSyncStatus(updateMap);
    _logger.fine('Updated ${updateMap.length} device folders backup status');
  }
}
