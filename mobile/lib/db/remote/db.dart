import "dart:developer";
import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/db/remote/migration.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/collection/collection.dart";
import "package:sqlite_async/sqlite_async.dart";

var devLog = log;

// ignore: constant_identifier_names
enum RemoteTable { collections, collection_files, files, entities }

class RemoteDB {
  static const _databaseName = "remotex2.db";
  static const _batchInsertMaxCount = 1000;
  late final SqliteDatabase _sqliteDB;

  Future<void> init() async {
    devLog("Starting RemoteDB init");
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    final database = SqliteDatabase(path: path);
    await RemoteDBMigration.migrate(database);
    _sqliteDB = database;
    devLog("RemoteDB init complete $path");
  }

  Future<List<Collection>> getAllCollections() async {
    final result = <Collection>[];
    final cursor = await _sqliteDB.getAll("SELECT * FROM collections");
    for (final row in cursor) {
      result.add(Collection.fromRow(row));
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
        'INSERT OR REPLACE INTO collections ($collectionColumns) values($collectionValuePlaceHolder)',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertCollections complete in ${stopwatch.elapsed.inMilliseconds}ms for ${collections.length} collections',
    );
  }

  Future<void> insertCollectionFilesDiff(
    List<CollectionFileItem> collections,
  ) async {
    if (collections.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(collections.slices(_batchInsertMaxCount),
        (slice) async {
      final List<List<Object?>> values = slice
          .map(
            (e) => [
              e.collectionID,
              e.fileID,
              e.encFileKey,
              e.encFileKeyNonce,
              e.createdAt,
              e.updatedAt,
              e.isDeleted ? 1 : 0,
            ],
          )
          .toList();
      await _sqliteDB.executeBatch(
        'INSERT OR REPLACE INTO collection_files ($collectionFilesColumns) values(?, ?, ?, ?, ?, ?, ?)',
        values,
      );
      final List<List<Object?>> fileValues = slice
          .map(
            (e) => [
              e.fileItem.fileID,
              e.fileItem.ownerID,
              e.fileItem.fileDecryotionHeader,
              e.fileItem.thumnailDecryptionHeader,
              e.fileItem.metadata?.toEncodedJson(),
              e.fileItem.magicMetadata?.toEncodedJson(),
              e.fileItem.pubMagicMetadata?.toEncodedJson(),
              e.fileItem.info?.toEncodedJson(),
            ],
          )
          .toList();
      await _sqliteDB.executeBatch(
        'INSERT OR REPLACE INTO files ($filesColumns) values(?, ?, ?, ?, ?, ?, ?, ?)',
        fileValues,
      );
    });
    debugPrint(
      '$runtimeType insertCollectionFilesDiff complete in ${stopwatch.elapsed.inMilliseconds}ms for ${collections.length}',
    );
  }

  Future<void> deleteCollectionFilesDiff(
    List<CollectionFileItem> items,
  ) async {
    if (items.isEmpty) return;
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
