import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/db/common/base.dart";
import "package:photos/db/local/mappers.dart";
import "package:photos/db/local/schema.dart";
import "package:photos/log/devlog.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/mapping/local_mapping.dart";
import "package:photos/models/local/local_metadata.dart";
import "package:sqlite_async/sqlite_async.dart";

class LocalDB with SqlDbBase {
  static const _databaseName = "local_6.db";
  static const batchInsertMaxCount = 1000;
  static const _smallTableBatchInsertMaxCount = 5000;
  late final SqliteDatabase _sqliteDB;
  SqliteDatabase get sqliteDB => _sqliteDB;

  Future<void> init() async {
    devLog("LocalDB init");
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    final db = SqliteDatabase(path: path);
    await migrate(db, LocalDBMigration.migrationScripts, onForeignKey: true);
    _sqliteDB = db;
    debugPrint("LocalDB init complete $path");
  }

  Future<void> insertAssets(List<AssetEntity> entries) async {
    if (entries.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(entries.slices(batchInsertMaxCount), (slice) async {
      final List<List<Object?>> values =
          slice.map((e) => LocalDBMappers.assetsRow(e)).toList();
      await _sqliteDB.executeBatch(
        'INSERT INTO assets ($assetColumns) values(${getParams(16)}) ON CONFLICT(id) DO UPDATE SET $updateAssetColumns',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertAssets complete in ${stopwatch.elapsed.inMilliseconds}ms for ${entries.length} assets',
    );
  }

// Store time and location metadata inside edited_assets
  Future<void> trackEdit(
    String id,
    int createdAt,
    int modifiedAt,
    double? lat,
    double? lng,
  ) async {
    final stopwatch = Stopwatch()..start();
    await _sqliteDB.execute(
      'INSERT INTO edited_assets (id, created_at, modified_at, latitude, longitude) VALUES (?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET created_at = ?, modified_at = ?, latitude = ?, longitude = ?',
      [id, createdAt, modifiedAt, lat, lng, createdAt, modifiedAt, lat, lng],
    );
    debugPrint(
      '$runtimeType editCopy complete in ${stopwatch.elapsed.inMilliseconds}ms for $id',
    );
  }
  ) async {
    final stopwatch = Stopwatch()..start();
    await _sqliteDB.execute(
      'INSERT INTO edited_assets (id, created_at, modified_at, latitude, longitude) VALUES (?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET created_at = ?, modified_at = ?, latitude = ?, longitude = ?',
      [id, createdAt, modifiedAt, lat, lng, createdAt, modifiedAt, lat, lng],
    );
    debugPrint(
      '$runtimeType editCopy complete in ${stopwatch.elapsed.inMilliseconds}ms for $id',
    );
  }

  Future<void> updateMetadata(
    String id, {
    DroidMetadata? droid,
    IOSMetadata? ios,
  }) async {
    if (droid != null) {
      await _sqliteDB.execute(
        'UPDATE assets SET size = ?, hash = ?, latitude = ?, longitude = ?, created_at = ?, modified_at = ?, scan_state = 1 WHERE id = ?',
        [
          droid.size,
          droid.hash,
          droid.location?.latitude,
          droid.location?.longitude,
          droid.creationTime,
          droid.modificationTime,
          id,
        ],
      );
    } else if (ios != null) {
      // await _sqliteDB.execute(
      //   'UPDATE assets SET size = ?, hash = ?, latitude = ?, longitude = ?, created_at = ?, modified_at = ? WHERE id = ?',
      //   [
      //     ios.size,
      //     ios.hash,
      //     ios.location.latitude,
      //     ios.location.longitude,
      //     ios.creationTime.millisecondsSinceEpoch,
      //     ios.modificationTime.millisecondsSinceEpoch,
      //     ios.id,
      //   ],
      // );
    }
  }

  Future<Map<String, LocalAssetInfo>> getLocalAssetsInfo(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    final stopwatch = Stopwatch()..start();
    final result = await _sqliteDB.getAll(
      'SELECT id, hash, title, relative_path, scan_state FROM assets WHERE id IN (${List.filled(ids.length, "?").join(",")})',
      ids,
    );
    debugPrint(
      "getLocalAssetsInfo complete in ${stopwatch.elapsed.inMilliseconds}ms for ${ids.length} ids",
    );
    return Map.fromEntries(
      result.map(
        (row) => MapEntry(row['id'] as String, LocalAssetInfo.fromRow(row)),
      ),
    );
  }

  Future<List<EnteFile>> getAssets({LocalAssertsParam? params}) async {
    final stopwatch = Stopwatch()..start();
    final result = await _sqliteDB.getAll(
      "SELECT * FROM assets ${params != null ? params.whereClause(addWhere: true) : ""}",
    );
    debugPrint(
      "getAssets complete in ${stopwatch.elapsed.inMilliseconds}ms, params: ${params?.whereClause()}",
    );
    // if time is greater than 1000ms, print explain analyze out
    if (kDebugMode && stopwatch.elapsed.inMilliseconds > 1000) {
      final explain = await _sqliteDB.execute(
        "EXPLAIN QUERY PLAN SELECT * FROM assets ${params != null ? params.whereClause(addWhere: true) : ""}",
      );
      debugPrint("getAssets: Explain Query Plan: $explain");
    }
    stopwatch.reset();
    stopwatch.start();
    final r =
        result.map((row) => LocalDBMappers.assetRowToEnteFile(row)).toList();
    debugPrint(
      "getAssets mapping completed in ${stopwatch.elapsed.inMilliseconds}ms",
    );
    return r;
  }

  Future<List<EnteFile>> getPathAssets(
    String pathID, {
    LocalAssertsParam? params,
  }) async {
    final String query =
        "SELECT * FROM assets WHERE id IN (SELECT asset_id FROM device_path_assets WHERE path_id = ?) ${params != null ? 'AND ${params.whereClause()}' : "order by created_at desc"}";
    debugPrint(query);
    final result = await _sqliteDB.getAll(
      query,
      [pathID],
    );
    return result.map((row) => LocalDBMappers.assetRowToEnteFile(row)).toList();
  }

  Future<void> insertDBPaths(List<AssetPathEntity> entries) async {
    if (entries.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(entries.slices(_smallTableBatchInsertMaxCount),
        (slice) async {
      final List<List<Object?>> values =
          slice.map((e) => LocalDBMappers.devicePathRow(e)).toList();
      await _sqliteDB.executeBatch(
        'INSERT INTO device_path ($devicePathColumns) values(${getParams(5)}) ON CONFLICT(path_id) DO UPDATE SET $updateDevicePathColumns',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertDBPaths complete in ${stopwatch.elapsed.inMilliseconds}ms for ${entries.length} paths',
    );
  }

  Future<List<AssetPathEntity>> getAssetPaths() async {
    final result = await _sqliteDB.getAll(
      "SELECT * FROM device_path",
    );
    return result.map((row) => LocalDBMappers.assetPath(row)).toList();
  }

  Future<void> insertPathToAssetIDs(
    Map<String, Set<String>> pathToAssetIDs, {
    bool clearOldMappingsIdsInInput = false,
  }) async {
    if (pathToAssetIDs.isEmpty) return;
    final List<List<String>> allValues = [];
    pathToAssetIDs.forEach((pathID, assetIDs) {
      allValues.addAll(assetIDs.map((assetID) => [pathID, assetID]));
    });
    if (allValues.isEmpty && !clearOldMappingsIdsInInput) {
      return;
    }
    final stopwatch = Stopwatch()..start();

    await _sqliteDB.writeTransaction((tx) async {
      if (clearOldMappingsIdsInInput) {
        await tx.execute(
          "DELETE FROM device_path_assets WHERE path_id IN (${List.generate(pathToAssetIDs.keys.length, (index) => '?').join(',')})",
          pathToAssetIDs.keys.toList(),
        );
      }
      const int batchSize = 15000;
      for (int i = 0; i < allValues.length; i += batchSize) {
        await tx.executeBatch(
          'INSERT OR REPLACE INTO device_path_assets (path_id, asset_id) VALUES (?, ?)',
          allValues.sublist(
            i,
            i + batchSize > allValues.length ? allValues.length : i + batchSize,
          ),
        );
      }
    });

    debugPrint(
      '$runtimeType insertPathToAssetIDs ${allValues.length} complete in '
      '${stopwatch.elapsed.inMilliseconds}ms for '
      '${pathToAssetIDs.length} paths (replaced $clearOldMappingsIdsInInput}',
    );
  }

  Future<Set<String>> getAssetsIDs({bool pendingScan = false}) async {
    final result = await _sqliteDB.getAll(
      "SELECT id FROM assets ${pendingScan ? 'WHERE scan_state != $finalState ORDER BY created_at DESC' : ''}",
    );
    final ids = <String>{};
    for (var row in result) {
      ids.add(row["id"] as String);
    }
    return ids;
  }

  Future<Map<String, int>> getIDToCreationTime() async {
    final result = await _sqliteDB.getAll(
      "SELECT id, created_at FROM assets",
    );
    final idToCreationTime = <String, int>{};
    for (var row in result) {
      idToCreationTime[row["id"] as String] = row["created_at"] as int;
    }
    return idToCreationTime;
  }

  Future<Map<String, Set<String>>> pathToAssetIDs() async {
    final result = await _sqliteDB
        .getAll("SELECT path_id, asset_id FROM device_path_assets");
    final pathToAssetIDs = <String, Set<String>>{};
    for (var row in result) {
      final pathID = row["path_id"] as String;
      final assetID = row["asset_id"] as String;
      if (pathToAssetIDs.containsKey(pathID)) {
        pathToAssetIDs[pathID]!.add(assetID);
      } else {
        pathToAssetIDs[pathID] = {assetID};
      }
    }
    return pathToAssetIDs;
  }

  Future<void> deleteAssets(Set<String> ids) async {
    if (ids.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await _sqliteDB.execute(
      'DELETE FROM assets WHERE id IN (${List.filled(ids.length, "?").join(",")})',
      ids.toList(),
    );
    debugPrint(
      '$runtimeType deleteEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${ids.length} assets entries',
    );
  }

  Future<void> deletePaths(Set<String> pathIds) async {
    if (pathIds.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await _sqliteDB.execute(
      'DELETE FROM device_path WHERE path_id IN (${List.filled(pathIds.length, "?").join(",")})',
      pathIds.toList(),
    );
    debugPrint(
      '$runtimeType deleteEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${pathIds.length} path entries',
    );
  }

  // returns true if either asset queue or shared_assets has any entry for given ownerID
  Future<bool> hasAssetQueueOrSharedAsset(int ownerID) async {
    final result = await _sqliteDB.getAll(
      '''
      SELECT 1 FROM asset_upload_queue WHERE owner_id = ? 
      UNION ALL
      SELECT 1 FROM shared_assets WHERE owner_id = ? 
      LIMIT 1
      ''',
      [ownerID, ownerID],
    );
    return result.isNotEmpty;
  }

  Future<(int, int)> getUniqueQueueAndSharedAssetsCount(
    int ownerID,
  ) async {
    final queuedAssets = await _sqliteDB.getAll(
      'SELECT COUNT(distinct asset_id) as count FROM asset_upload_queue WHERE owner_id = ?',
      [ownerID],
    );
    final sharedAssets = await _sqliteDB.getAll(
      'SELECT COUNT(*) as count FROM shared_assets WHERE owner_id = ?',
      [ownerID],
    );
    final queuedCount =
        queuedAssets.isNotEmpty ? (queuedAssets.first['count'] as int) : 0;
    final sharedCount =
        sharedAssets.isNotEmpty ? (sharedAssets.first['count'] as int) : 0;
    return (queuedCount, sharedCount);
  }
}
