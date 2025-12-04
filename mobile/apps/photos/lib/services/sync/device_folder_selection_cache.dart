// Provides the FilesDB.getDeviceCollections extension.
import "package:photos/db/device_files_db.dart";
import "package:photos/db/files_db.dart";

class DeviceFolderSelectionCache {
  DeviceFolderSelectionCache._();

  static final DeviceFolderSelectionCache instance =
      DeviceFolderSelectionCache._();

  final Set<String> _selectedPathIds = <String>{};
  final Map<int, String> _collectionIdToPathId = <int, String>{};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
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
    _initialized = true;
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
    for (final entry in updates.entries) {
      if (entry.value) {
        _selectedPathIds.add(entry.key);
      } else {
        _selectedPathIds.remove(entry.key);
      }
    }
  }

  void setCollectionIdMapping(int collectionId, String pathId) {
    _collectionIdToPathId[collectionId] = pathId;
  }

  void clear() {
    _selectedPathIds.clear();
    _collectionIdToPathId.clear();
    _initialized = false;
  }
}
