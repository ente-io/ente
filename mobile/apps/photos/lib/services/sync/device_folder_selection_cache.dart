// Provides the FilesDB.getDeviceCollections extension.
import "dart:async";

import "package:photos/db/device_files_db.dart";
import "package:photos/db/files_db.dart";
import "package:photos/service_locator.dart";

class DeviceFolderSelectionCache {
  DeviceFolderSelectionCache._();

  static final DeviceFolderSelectionCache instance =
      DeviceFolderSelectionCache._();

  final Set<String> _selectedPathIds = <String>{};
  final Map<int, String> _collectionIdToPathId = <int, String>{};
  bool _initialized = false;
  Completer<void>? _initCompleter;

  bool get isInitialized => _initialized;

  Future<void> ensureInitialized() async {
    if (!flagService.enableBackupFolderSync) return;
    if (_initialized) return;
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      await _loadFromDB();
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> _loadFromDB() async {
    final deviceCollections = await FilesDB.instance.getDeviceCollections();
    _selectedPathIds.clear();
    _collectionIdToPathId.clear();
    for (final dc in deviceCollections) {
      if (dc.shouldBackup) {
        _selectedPathIds.add(dc.id);
      }
      if (dc.hasCollectionID()) {
        _collectionIdToPathId[dc.collectionID!] = dc.id;
      }
    }
  }

  bool isSelected(String pathId) {
    if (!_initialized) {
      return true;
    }
    return _selectedPathIds.contains(pathId);
  }

  String? getPathIdForCollectionId(int collectionId) {
    return _collectionIdToPathId[collectionId];
  }

  void update(Map<String, bool> updates) {
    if (!flagService.enableBackupFolderSync) return;
    for (final entry in updates.entries) {
      if (entry.value) {
        _selectedPathIds.add(entry.key);
      } else {
        _selectedPathIds.remove(entry.key);
      }
    }
  }

  void setCollectionIdMapping(int collectionId, String pathId) {
    if (!flagService.enableBackupFolderSync) return;
    _collectionIdToPathId[collectionId] = pathId;
  }

  void clear() {
    _selectedPathIds.clear();
    _collectionIdToPathId.clear();
    _initialized = false;
  }
}
