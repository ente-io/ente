import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/services/sync/remote_sync_service.dart';

class BackupPreferenceService {
  BackupPreferenceService._();

  static final BackupPreferenceService instance = BackupPreferenceService._();
  final Logger _logger = Logger('BackupPreferenceService');

  Future<void> autoSelectAllFoldersIfEligible() async {
    final config = Configuration.instance;
    if (config.hasManualFolderSelection() ||
        config.hasSelectedAnyBackupFolder()) {
      return;
    }
    await config.setHasManualFolderSelection(true);
    await _setAllFoldersShouldBackup(true);
    await config.setSelectAllFoldersForBackup(true);
    await config.setHasSelectedAnyBackupFolder(true);
    _logger.info('Auto-selected all folders for backup');
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
