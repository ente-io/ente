import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:photos/db/local/db.dart";
import "package:photos/db/local/schema.dart";

extension UploadQueueTable on LocalDB {
  Future<Set<String>> getQueueAssetIDs(int ownerID) async {
    final stopwatch = Stopwatch()..start();
    final result = await sqliteDB.getAll(
      'SELECT asset_id FROM asset_upload_queue WHERE   owner_id = ?',
      [ownerID],
    );
    final assetIDs = result.map((row) => row['asset_id'] as String).toSet();
    debugPrint(
      '$runtimeType getQueueAssetIDs complete in ${stopwatch.elapsed.inMilliseconds}ms',
    );
    return assetIDs;
  }

  Future<void> clearMappingsWithPath(
    int ownerID,
    Set<int> collectionIDs,
  ) async {
    if (collectionIDs.isEmpty) {
      return;
    }
    await sqliteDB.executeBatch(
      'DELETE FROM asset_upload_queue WHERE owner_id = $ownerID AND dest_collection_id IN (${collectionIDs.join(',')}) AND path_id IS NOT NULL',
      [],
    );
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
