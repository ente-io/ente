// @dart = 2.9
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/upload_strategy.dart';
import 'package:photos/services/local/local_sync_util.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:tuple/tuple.dart';

extension DeviceFiles on FilesDB {
  static final Logger _logger = Logger("DeviceFilesDB");
  static const _sqlBoolTrue = 1;
  static const _sqlBoolFalse = 0;

  Future<void> insertPathIDToLocalIDMapping(
    Map<String, Set<String>> mappingToAdd, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.ignore,
  }) async {
    debugPrint("Inserting missing PathIDToLocalIDMapping");
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (MapEntry e in mappingToAdd.entries) {
      final String pathID = e.key;
      for (String localID in e.value) {
        if (batchCounter == 400) {
          await batch.commit(noResult: true);
          batch = db.batch();
          batchCounter = 0;
        }
        batch.insert(
          "device_files",
          {
            "id": localID,
            "path_id": pathID,
          },
          conflictAlgorithm: conflictAlgorithm,
        );
        batchCounter++;
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePathIDToLocalIDMapping(
    Map<String, Set<String>> mappingsToRemove,
  ) async {
    debugPrint("removing PathIDToLocalIDMapping");
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (MapEntry e in mappingsToRemove.entries) {
      final String pathID = e.key;
      for (String localID in e.value) {
        if (batchCounter == 400) {
          await batch.commit(noResult: true);
          batch = db.batch();
          batchCounter = 0;
        }
        batch.delete(
          "device_files",
          where: 'id = ? AND path_id = ?',
          whereArgs: [localID, pathID],
        );
        batchCounter++;
      }
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> getDevicePathIDToImportedFileCount() async {
    try {
      final db = await database;
      final rows = await db.rawQuery(
        '''
      SELECT count(*) as count, path_id
      FROM device_files
      GROUP BY path_id
    ''',
      );
      final result = <String, int>{};
      for (final row in rows) {
        result[row['path_id']] = row["count"];
      }
      return result;
    } catch (e) {
      _logger.severe("failed to getDevicePathIDToImportedFileCount", e);
      rethrow;
    }
  }

  Future<Map<String, Set<String>>> getDevicePathIDToLocalIDMap() async {
    try {
      final db = await database;
      final rows = await db.rawQuery(
        ''' SELECT id, path_id FROM device_files; ''',
      );
      final result = <String, Set<String>>{};
      for (final row in rows) {
        final String pathID = row['path_id'];
        if (!result.containsKey(pathID)) {
          result[pathID] = <String>{};
        }
        result[pathID].add(row['id']);
      }
      return result;
    } catch (e) {
      _logger.severe("failed to getDevicePathIDToLocalIDMap", e);
      rethrow;
    }
  }

  Future<Set<String>> getDevicePathIDs() async {
    final Database db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT id FROM device_collections
      ''',
    );
    final Set<String> result = <String>{};
    for (final row in rows) {
      result.add(row['id']);
    }
    return result;
  }

  Future<void> insertLocalAssets(
    List<LocalPathAsset> localPathAssets, {
    bool shouldAutoBackup = false,
  }) async {
    final Database db = await database;
    final Map<String, Set<String>> pathIDToLocalIDsMap = {};
    try {
      final batch = db.batch();
      final Set<String> existingPathIds = await getDevicePathIDs();
      for (LocalPathAsset localPathAsset in localPathAssets) {
        if (localPathAsset.localIDs.isNotEmpty) {
          pathIDToLocalIDsMap[localPathAsset.pathID] = localPathAsset.localIDs;
        }
        if (existingPathIds.contains(localPathAsset.pathID)) {
          batch.rawUpdate(
            "UPDATE device_collections SET name = ? where id = "
            "?",
            [localPathAsset.pathName, localPathAsset.pathID],
          );
        } else if (localPathAsset.localIDs.isNotEmpty) {
          batch.insert(
            "device_collections",
            {
              "id": localPathAsset.pathID,
              "name": localPathAsset.pathName,
              "should_backup": shouldAutoBackup ? _sqlBoolTrue : _sqlBoolFalse
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      await batch.commit(noResult: true);
      // add the mappings for localIDs
      if (pathIDToLocalIDsMap.isNotEmpty) {
        await insertPathIDToLocalIDMapping(pathIDToLocalIDsMap);
      }
    } catch (e) {
      _logger.severe("failed to save path names", e);
      rethrow;
    }
  }

  Future<bool> updateDeviceCoverWithCount(
    List<Tuple2<AssetPathEntity, String>> devicePathInfo, {
    bool shouldBackup = false,
  }) async {
    bool hasUpdated = false;
    try {
      final Database db = await database;
      final Set<String> existingPathIds = await getDevicePathIDs();
      for (Tuple2<AssetPathEntity, String> tup in devicePathInfo) {
        final AssetPathEntity pathEntity = tup.item1;
        final String localID = tup.item2;
        final bool shouldUpdate = existingPathIds.contains(pathEntity.id);
        if (shouldUpdate) {
          final rowUpdated = await db.rawUpdate(
            "UPDATE device_collections SET name = ?, cover_id = ?, count"
            " = ? where id = ? AND (name != ? OR cover_id != ? OR count != ?)",
            [
              pathEntity.name,
              localID,
              pathEntity.assetCount,
              pathEntity.id,
              pathEntity.name,
              localID,
              pathEntity.assetCount,
            ],
          );
          if (rowUpdated > 0) {
            _logger.fine("Updated $rowUpdated rows for ${pathEntity.name}");
            hasUpdated = true;
          }
        } else {
          hasUpdated = true;
          await db.insert(
            "device_collections",
            {
              "id": pathEntity.id,
              "name": pathEntity.name,
              "count": pathEntity.assetCount,
              "cover_id": localID,
              "should_backup": shouldBackup ? _sqlBoolTrue : _sqlBoolFalse
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      // delete existing pathIDs which are missing on device
      existingPathIds.removeAll(devicePathInfo.map((e) => e.item1.id).toSet());
      if (existingPathIds.isNotEmpty) {
        hasUpdated = true;
        _logger.info('Deleting following pathIds from local $existingPathIds ');
        for (String pathID in existingPathIds) {
          await db.delete(
            "device_collections",
            where: 'id = ?',
            whereArgs: [pathID],
          );
          await db.delete(
            "device_files",
            where: 'path_id = ?',
            whereArgs: [pathID],
          );
        }
      }
      return hasUpdated;
    } catch (e) {
      _logger.severe("failed to save path names", e);
      rethrow;
    }
  }

  // getDeviceSyncCollectionIDs returns the collectionIDs for the
  // deviceCollections which are marked for auto-backup
  Future<Set<int>> getDeviceSyncCollectionIDs() async {
    final Database db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT collection_id FROM device_collections where should_backup = 
      $_sqlBoolTrue 
      and collection_id != -1;
      ''',
    );
    final Set<int> result = <int>{};
    for (final row in rows) {
      result.add(row['collection_id']);
    }
    return result;
  }

  Future<void> updateDevicePathSyncStatus(Map<String, bool> syncStatus) async {
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (MapEntry e in syncStatus.entries) {
      final String pathID = e.key;
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.update(
        "device_collections",
        {
          "should_backup": e.value ? _sqlBoolTrue : _sqlBoolFalse,
        },
        where: 'id = ?',
        whereArgs: [pathID],
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateDeviceCollection(
    String pathID,
    int collectionID,
  ) async {
    final db = await database;
    await db.update(
      "device_collections",
      {"collection_id": collectionID},
      where: 'id = ?',
      whereArgs: [pathID],
    );
    return;
  }

  Future<FileLoadResult> getFilesInDeviceCollection(
    DeviceCollection deviceCollection,
    int startTime,
    int endTime, {
    int limit,
    bool asc,
  }) async {
    final db = await database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    final String rawQuery = '''
    SELECT *
          FROM ${FilesDB.filesTable}
          WHERE ${FilesDB.columnLocalID} IS NOT NULL AND
          ${FilesDB.columnCreationTime} >= $startTime AND 
          ${FilesDB.columnCreationTime} <= $endTime AND 
          ${FilesDB.columnLocalID} IN 
          (SELECT id FROM device_files where path_id = '${deviceCollection.id}' ) 
          ORDER BY ${FilesDB.columnCreationTime} $order , ${FilesDB.columnModificationTime} $order
         ''' +
        (limit != null ? ' limit $limit;' : ';');
    final results = await db.rawQuery(rawQuery);
    final files = convertToFiles(results);
    final dedupe = deduplicateByLocalID(files);
    return FileLoadResult(dedupe, files.length == limit);
  }

  Future<List<DeviceCollection>> getDeviceCollections({
    bool includeCoverThumbnail = false,
  }) async {
    debugPrint(
      "Fetching DeviceCollections From DB with thumbnail = "
      "$includeCoverThumbnail",
    );
    try {
      final db = await database;
      final coverFiles = <File>[];
      if (includeCoverThumbnail) {
        final fileRows = await db.rawQuery(
          '''SELECT * FROM FILES where local_id in (select cover_id from device_collections) group by local_id;
          ''',
        );
        final files = convertToFiles(fileRows);
        coverFiles.addAll(files);
      }
      final deviceCollectionRows = await db.rawQuery(
        '''SELECT * from device_collections''',
      );
      final List<DeviceCollection> deviceCollections = [];
      for (var row in deviceCollectionRows) {
        final DeviceCollection deviceCollection = DeviceCollection(
          row["id"],
          row['name'],
          count: row['count'],
          collectionID: row["collection_id"],
          coverId: row["cover_id"],
          shouldBackup: (row["should_backup"] ?? _sqlBoolFalse) == _sqlBoolTrue,
          uploadStrategy: getUploadType(row["upload_strategy"] ?? 0),
        );
        if (includeCoverThumbnail) {
          deviceCollection.thumbnail = coverFiles.firstWhere(
            (element) => element.localID == deviceCollection.coverId,
            orElse: () => null,
          );
          if (deviceCollection.thumbnail == null) {
            final File result =
                await getDeviceCollectionThumbnail(deviceCollection.id);
            if (result == null) {
              _logger.severe(
                'Failed to find coverThumbnail for deviceFolder',
              );
              continue;
            } else {
              deviceCollection.thumbnail = result;
            }
          }
        }
        deviceCollections.add(deviceCollection);
      }
      if (includeCoverThumbnail) {
        deviceCollections.sort(
          (a, b) =>
              b.thumbnail.creationTime.compareTo(a.thumbnail.creationTime),
        );
      }
      return deviceCollections;
    } catch (e) {
      _logger.severe('Failed to getDeviceCollections', e);
      rethrow;
    }
  }

  Future<File> getDeviceCollectionThumbnail(String pathID) async {
    debugPrint("Call fallback method to get potential thumbnail");
    final db = await database;
    final fileRows = await db.rawQuery(
      '''SELECT * FROM FILES  f JOIN device_files df on f.local_id = df.id 
      and df.path_id= ? order by f.modification_time DESC limit 1;
          ''',
      [pathID],
    );
    final files = convertToFiles(fileRows);
    if (files.isNotEmpty) {
      return files.first;
    } else {
      return null;
    }
  }
}
