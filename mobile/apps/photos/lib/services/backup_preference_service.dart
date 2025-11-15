import 'package:photos/core/configuration.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/services/sync/remote_sync_service.dart';

class BackupPreferenceService {
  BackupPreferenceService._();

  static final BackupPreferenceService instance = BackupPreferenceService._();

  Future<void> autoSelectAllFoldersIfEligible() async {
    final config = Configuration.instance;
    if (config.hasManualFolderSelection()) {
      return;
    }
    await _setAllFoldersShouldBackup(true);
    await config.setSelectAllFoldersForBackup(true);
    await config.setHasSelectedAnyBackupFolder(true);
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
  }
}
