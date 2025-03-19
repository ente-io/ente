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
import "package:sqlite_async/sqlite_async.dart";

class LocalDB with SqlDbBase {
  static const _databaseName = "local_3.db";
  static const _batchInsertMaxCount = 1000;
  static const _smallTableBatchInsertMaxCount = 5000;
  late final SqliteDatabase _sqliteDB;

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
    await Future.forEach(entries.slices(_batchInsertMaxCount), (slice) async {
      final List<List<Object?>> values =
          slice.map((e) => LocalDBMappers.assetsRow(e)).toList();
      await _sqliteDB.executeBatch(
        'INSERT OR REPLACE INTO assets ($assetColumns) values(${getParams(15)})',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertAssets complete in ${stopwatch.elapsed.inMilliseconds}ms for ${entries.length} assets',
    );
  }

  Future<void> insertDBPaths(List<AssetPathEntity> entries) async {
    if (entries.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(entries.slices(_smallTableBatchInsertMaxCount),
        (slice) async {
      final List<List<Object?>> values =
          slice.map((e) => LocalDBMappers.devicePathRow(e)).toList();
      await _sqliteDB.executeBatch(
        'INSERT OR REPLACE INTO device_path ($devicePathColumns) values(${getParams(5)})',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertDBPaths complete in ${stopwatch.elapsed.inMilliseconds}ms for ${entries.length} paths',
    );
  }

  Future<List<AssetPathEntity>> getAssetPaths() async {
    final result = await _sqliteDB.execute(
      "SELECT * FROM device_path",
    );
    return result.map((row) => LocalDBMappers.assetPath(row)).toList();
  }

  Future<void> insertPathToAssetIDs(
    Map<String, Set<String>> pathToAssetIDs, {
    bool clearOldMappingsIdsInInput = false,
  }) async {
    if (pathToAssetIDs.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    late int pairCount;

    await _sqliteDB.writeTransaction((tx) async {
      if (clearOldMappingsIdsInInput) {
        await tx.execute(
          "DELETE FROM device_path_assets WHERE path_id IN (${List.generate(pathToAssetIDs.keys.length, (index) => '?').join(',')})",
          pathToAssetIDs.keys.toList(),
        );
      }
      final List<List<String>> allValues = [];

      pathToAssetIDs.forEach((pathID, assetIDs) {
        allValues.addAll(assetIDs.map((assetID) => [pathID, assetID]));
      });
      pairCount = allValues.length;
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
      '$runtimeType insertPathToAssetIDs $pairCount complete in '
      '${stopwatch.elapsed.inMilliseconds}ms for '
      '${pathToAssetIDs.length} paths (replaced $clearOldMappingsIdsInInput}',
    );
  }

  Future<Set<String>> getAssetsIDs() async {
    final result = await _sqliteDB.execute("SELECT id FROM assets");
    final ids = <String>{};
    for (var row in result) {
      ids.add(row["id"] as String);
    }
    return ids;
  }

  Future<Map<String, Set<String>>> pathToAssetIDs() async {
    final result = await _sqliteDB
        .execute("SELECT path_id, asset_id FROM device_path_assets");
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
      'DELETE FROM assets WHERE id IN (${ids.join(',')})',
    );
    debugPrint(
      '$runtimeType deleteEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${ids.length} assets entries',
    );
  }

  Future<void> deletePaths(Set<String> pathIds) async {
    if (pathIds.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await _sqliteDB.execute(
      'DELETE FROM device_path WHERE path_id IN (${pathIds.join(',')})',
    );
    debugPrint(
      '$runtimeType deleteEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${pathIds.length} path entries',
    );
  }
}
