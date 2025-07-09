import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:photos/db/local/db.dart";
import "package:photos/db/local/schema.dart";
import "package:photos/models/local/asset_upload_queue.dart";

extension UploadQueueTable on LocalDB {
  Future<Set<String>> getQueueAssetIDs(int ownerID) async {
    final stopwatch = Stopwatch()..start();
    final result = await sqliteDB.getAll(
      'SELECT asset_id FROM asset_upload_queue WHERE   owner_id = ?',
      [ownerID],
    );
    final assetIDs = result.map((row) => row['id'] as String).toSet();
    debugPrint(
      '$runtimeType getQueueAssetIDs complete in ${stopwatch.elapsed.inMilliseconds}ms',
    );
    return assetIDs;
  }

  Future<void> clearMappingsWithDiffPath(
    int ownerID,
    Set<String> pathIDs,
  ) async {
    if (pathIDs.isEmpty) {
      // delete all mapping with path ids
      await sqliteDB.execute(
        'DELETE FROM asset_upload_queue WHERE owner_id = ? AND path_id IS NOT NULL',
        [ownerID],
      );
    } else {
      // delete mappings where path_id is not null and not in pathIDs
      final stopwatch = Stopwatch()..start();
      await sqliteDB.execute(
        'DELETE FROM asset_upload_queue WHERE owner_id = ? AND path_id IS NOT NULL AND path_id NOT IN (${pathIDs.map((_) => '?').join(',')})',
        [ownerID, ...pathIDs],
      );
      debugPrint(
        '$runtimeType clearMappingsWithDiffPath complete in ${stopwatch.elapsed.inMilliseconds}ms for ${pathIDs.length} paths',
      );
    }
  }

  Future<List<AssetUploadQueue>> getQueueEntries(
    int ownerID, {
    int? destCollection,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await sqliteDB.getAll(
      'SELECT asset_upload_queue.*, assets.* FROM asset_upload_queue JOIN assets ON assets.id = asset_upload_queue.asset_id WHERE owner_id = ? ${destCollection != null ? 'AND dest_collection_id = ?' : ''} ORDER BY created_at DESC',
      destCollection != null ? [ownerID, destCollection] : [ownerID],
    );
    final entries = result
        .map(
          (row) => AssetUploadQueue(
            id: row['asset_id'] as String,
            pathId: row['path_id'] as String?,
            destCollectionId: row['dest_collection_id'] as int,
            ownerId: row['owner_id'] as int,
            manual: (row['manual'] as int) == 1,
          ),
        )
        .toList();
    debugPrint(
      '$runtimeType getQueueEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${entries.length} entries',
    );
    return entries;
  }

  Future<void> insertOrUpdateQueue(
    Set<String> assetIDs,
    int destCollection,
    int ownerID, {
    String? path,
    bool manual = false,
  }) async {
    if (assetIDs.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(
      assetIDs.slices(LocalDB.batchInsertMaxCount),
      (slice) async {
        final List<List<Object?>> values = slice
            .map((e) => [destCollection, e, path, ownerID, manual])
            .toList();
        await sqliteDB.executeBatch(
          'INSERT INTO asset_upload_queue ($assetUploadQueueColumns) VALUES(?,?,?,?,?) ON CONFLICT DO UPDATE SET manual = ?, path_id = ?',
          values
              .map((e) => [e[0], e[1], e[2], e[3], e[4], manual, path])
              .toList(),
        );
      },
    );
    debugPrint(
      '$runtimeType insertOrUpdateQueue complete in ${stopwatch.elapsed.inMilliseconds}ms for ${assetIDs.length} items',
    );
  }
}
