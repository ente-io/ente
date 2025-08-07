import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:photos/db/local/db.dart";
import "package:photos/log/devlog.dart";
import "package:photos/models/local/path_config.dart";
import "package:photos/models/upload_strategy.dart";

extension PathBackupConfigTable on LocalDB {
  Future<void> insertOrUpdatePathConfigs(
    Map<String, bool> pathConfigs,
    int ownerID,
  ) async {
    if (pathConfigs.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(
        pathConfigs.entries.slices(LocalDB.batchInsertMaxCount), (slice) async {
      final List<List<Object?>> values =
          slice.map((e) => [e.key, e.value ? 1 : 0, ownerID]).toList();
      await sqliteDB.executeBatch(
        'INSERT INTO path_backup_config (device_path_id, should_backup, owner_id) VALUES (?, ?, ?) ON CONFLICT(device_path_id) DO UPDATE SET should_backup = ?, owner_id = ?',
        values.map((e) => [e[0], e[1], e[2], e[1], e[2]]).toList(),
      );
    });
    debugPrint(
      '$runtimeType insertOrUpdatePathConfigs complete in ${stopwatch.elapsed.inMilliseconds}ms for ${pathConfigs.length} paths',
    );
  }

  Future<Set<String>> getBackedUpPathIDs(int ownerID) async {
    final stopwatch = Stopwatch()..start();
    final result = await sqliteDB.getAll(
      'SELECT device_path_id FROM path_backup_config WHERE should_backup = 1 AND owner_id = ?',
      [ownerID],
    );
    final paths = result.map((row) => row['device_path_id'] as String).toSet();
    devLog(
      '$runtimeType getPathsWithBackupEnabled complete in ${stopwatch.elapsed.inMilliseconds}ms',
      name: 'getPathsWithBackupEnabled',
    );
    return paths;
  }

  // destCollectionWithBackup returns the non-null collection ids
  // for given ownerID for paths that have backup enabled.
  Future<Set<int>> destCollectionWithBackup(int ownerID) async {
    final stopwatch = Stopwatch()..start();
    final result = await sqliteDB.getAll(
      'SELECT collection_id FROM path_backup_config WHERE should_backup = 1 AND owner_id = ? AND collection_id IS NOT NULL',
      [ownerID],
    );
    final Set<int> collectionIDs =
        result.map((row) => row['collection_id'] as int).whereNotNull().toSet();
    devLog(
      '$runtimeType destCollectionWithBackup complete in ${stopwatch.elapsed.inMilliseconds}ms',
      name: 'destCollectionWithBackup',
    );
    return collectionIDs;
  }

  Future<void> updateDestConnection(
    String pathID,
    int destCollection,
    int ownerID,
  ) async {
    await sqliteDB.execute(
      'UPDATE path_backup_config SET collection_id = ? WHERE device_path_id = ? AND owner_id = ?',
      [destCollection, pathID, ownerID],
    );
  }

  Future<List<PathConfig>> getPathConfigs(int ownerID) async {
    final stopwatch = Stopwatch()..start();
    final result = await sqliteDB.getAll(
      'SELECT * FROM path_backup_config WHERE owner_id = ?',
      [ownerID],
    );
    final configs = result.map((row) {
      return PathConfig(
        row['device_path_id'] as String,
        row['owner_id'] as int,
        row['collection_id'] as int?,
        (row['should_backup'] as int) == 1,
        getUploadType(row['upload_strategy'] as int),
      );
    }).toList();
    devLog(
      '$runtimeType getPathConfigs complete in ${stopwatch.elapsed.inMilliseconds}ms',
      name: 'getPathConfigs',
    );
    return configs;
  }
}
