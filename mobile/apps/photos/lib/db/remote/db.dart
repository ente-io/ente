import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/db/common/base.dart";
import "package:photos/db/remote/mappers.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/log/devlog.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:sqlite_async/sqlite_async.dart";

// ignore: constant_identifier_names
enum RemoteTable { collections, collection_files, files, entities, trash }

class RemoteDB with SqlDbBase {
  static const _databaseName = "remotex6.db";
  static const _batchInsertMaxCount = 1000;
  late final SqliteDatabase _sqliteDB;

  Future<void> init() async {
    devLog("Starting RemoteDB init");
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    final db = SqliteDatabase(path: path);
    await migrate(db, RemoteDBMigration.migrationScripts, onForeignKey: true);
    _sqliteDB = db;
    debugPrint("RemoteDB init complete $path");
  }

  SqliteDatabase get sqliteDB => _sqliteDB;

  Future<List<Collection>> getAllCollections() async {
    final result = <Collection>[];
    final cursor = await _sqliteDB.getAll("SELECT * FROM collections");
    for (final row in cursor) {
      result.add(Collection.fromRow(row));
    }
    return result;
  }

  Future<void> clearAllTables() async {
    final stopwatch = Stopwatch()..start();
    await Future.wait([
      _sqliteDB.execute('DELETE FROM collections'),
      _sqliteDB.execute('DELETE FROM collection_files'),
      _sqliteDB.execute('DELETE FROM files'),
      _sqliteDB.execute('DELETE FROM files_metadata'),
      _sqliteDB.execute('DELETE FROM trash'),
      _sqliteDB.execute('DELETE FROM upload_mapping'),
    ]);
    debugPrint(
      '$runtimeType clearAllTables complete in ${stopwatch.elapsed.inMilliseconds}ms',
    );
  }

  Future<Map<int, int>> getCollectionIDToUpdationTime() async {
    final result = <int, int>{};
    final cursor = await _sqliteDB.getAll(
      "SELECT id, updation_time FROM collections where is_deleted = 0",
    );
    for (final row in cursor) {
      result[row['id'] as int] = row['updation_time'] as int;
    }
    return result;
  }

  Future<List<RemoteAsset>> getRemoteAssets() async {
    final result = <RemoteAsset>[];
    final cursor = await _sqliteDB.getAll(
      "SELECT * FROM files",
    );
    for (final row in cursor) {
      result.add(fromFilesRow(row));
    }
    return result;
  }

  Future<void> insertCollections(List<Collection> collections) async {
    if (collections.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(collections.slices(_batchInsertMaxCount),
        (slice) async {
      final List<List<Object?>> values =
          slice.map((e) => e.rowValiues()).toList();
      await _sqliteDB.executeBatch(
        'INSERT INTO collections ($collectionColumns) values($collectionValuePlaceHolder) ON CONFLICT(id) DO UPDATE SET $updateCollectionColumns',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertCollections complete in ${stopwatch.elapsed.inMilliseconds}ms for ${collections.length} collections',
    );
  }

  Future<List<RemoteAsset>> insertDiffItems(
    List<DiffItem> items,
  ) async {
    if (items.isEmpty) return [];
    final List<RemoteAsset> assets = [];
    final stopwatch = Stopwatch()..start();
    await Future.forEach(items.slices(_batchInsertMaxCount), (slice) async {
      final List<List<Object?>> collectionFileValues = [];
      final List<List<Object?>> fileValues = [];
      final List<List<Object?>> fileMetadataValues = [];
      for (final item in slice) {
        final rAsset = item.fileItem.toRemoteAsset();
        collectionFileValues.add(item.collectionFileRowValues());
        fileMetadataValues.add(item.fileItem.filesMetadataRowValues());
        fileValues.add(remoteAssetToRow(rAsset));
        assets.add(rAsset);
      }
      await Future.wait([
        _sqliteDB.executeBatch(
          'INSERT INTO collection_files ($collectionFilesColumns) values(?, ?, ?, ?, ?, ?) ON CONFLICT(file_id, collection_id) DO UPDATE SET $collectionFilesUpdateColumns',
          collectionFileValues,
        ),
        _sqliteDB.executeBatch(
          'INSERT INTO files ($filesColumns) values(${getParams(23)}) ON CONFLICT(id) DO UPDATE SET $filesUpdateColumns',
          fileValues,
        ),
        _sqliteDB.executeBatch(
          'INSERT INTO files_metadata ($filesMetadataColumns) values(${getParams(5)}) ON CONFLICT(id) DO UPDATE SET $filesMetadataUpdateColumns',
          fileMetadataValues,
        ),
      ]);
    });
    debugPrint(
      '$runtimeType insertCollectionFilesDiff complete in ${stopwatch.elapsed.inMilliseconds}ms for ${items.length}',
    );
    return assets;
  }

  Future<void> deleteFilesDiff(
    List<DiffItem> items,
  ) async {
    final int collectionID = items.first.collectionID;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(items.slices(_batchInsertMaxCount), (slice) async {
      await _sqliteDB.execute(
        'DELETE FROM collection_files WHERE file_id IN (${slice.map((e) => e.fileID).join(',')}) AND collection_id = $collectionID',
      );
    });
    debugPrint(
      '$runtimeType deleteCollectionFilesDiff complete in ${stopwatch.elapsed.inMilliseconds}ms for ${items.length}',
    );
  }

  Future<void> deleteEntries<T>(Set<T> ids, RemoteTable table) async {
    if (ids.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await _sqliteDB.execute(
      'DELETE FROM ${table.name.toLowerCase()} WHERE id IN (${ids.join(',')})',
    );
    debugPrint(
      '$runtimeType deleteEntries complete in ${stopwatch.elapsed.inMilliseconds}ms for ${ids.length} $table entries',
    );
  }

  Future<int> rowCount(
    RemoteTable table,
  ) async {
    final row = await _sqliteDB.get(
      'SELECT COUNT(*) as count FROM ${table.name}',
    );
    return row['count'] as int;
  }

  Future<Set<T>> _getByIds<T>(
    Set<int> ids,
    String table,
    T Function(
      Map<String, Object?> row,
    ) mapRow, {
    String columnName = "id",
  }) async {
    final result = <T>{};
    if (ids.isNotEmpty) {
      final rows = await _sqliteDB.getAll(
        'SELECT * from $table where $columnName IN (${ids.join(',')})',
      );
      for (final row in rows) {
        result.add(mapRow(row));
      }
    }
    return result;
  }
}
