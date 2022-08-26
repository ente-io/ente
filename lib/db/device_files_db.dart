import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/services/local/local_sync_util.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:tuple/tuple.dart';

extension DeviceFiles on FilesDB {
  static final Logger _logger = Logger("DeviceFilesDB");
  static const _sqlBoolTrue = 1;
  static const _sqlBoolFalse = 0;

  // insertPathIDToLocalIDMapping is used to insert of update the pathID
  // to localID mapping.
  Future<void> insertPathIDToLocalIDMapping(
    Map<String, Set<String>> mappingToAdd, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.ignore,
    bool syncStatus = false,
  }) async {
    debugPrint("Inserting missing PathIDToLocalIDMapping");
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (MapEntry e in mappingToAdd.entries) {
      String pathID = e.key;
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
            "synced": syncStatus ? _sqlBoolTrue : _sqlBoolFalse
          },
          conflictAlgorithm: conflictAlgorithm,
        );
        batchCounter++;
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePathIDToLocalIDMapping(
      Map<String, Set<String>> mappingsToRemove) async {
    debugPrint("removing PathIDToLocalIDMapping");
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (MapEntry e in mappingsToRemove.entries) {
      String pathID = e.key;
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

  Future<Map<String, Set<String>>> getDevicePathIDToLocalIDMap({
    bool syncStatus,
  }) async {
    try {
      final db = await database;
      String query = 'SELECT id, path_id FROM device_files';
      if (syncStatus != null) {
        query =
            'SELECT id, path_id FROM device_files where synced = ${syncStatus ? _sqlBoolTrue : _sqlBoolFalse} ;';
      }
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
      SELECT id FROM device_path_collections
      ''',
    );
    final Set<String> result = <String>{};
    for (final row in rows) {
      result.add(row['id']);
    }
    return result;
  }

  // todo: covert it to batch
  Future<void> insertLocalAssets(
    List<LocalPathAsset> localPathAssets, {
    bool autoSync = false,
  }) async {
    final Database db = await database;
    final Map<String, Set<String>> pathIDToLocalIDsMap = {};
    try {
      final Set<String> existingPathIds = await getDevicePathIDs();
      for (LocalPathAsset localPathAsset in localPathAssets) {
        pathIDToLocalIDsMap[localPathAsset.pathID] = localPathAsset.localIDs;
        if (existingPathIds.contains(localPathAsset.pathID)) {
          await db.rawUpdate(
            "UPDATE device_path_collections SET name = ? where id = "
            "?",
            [localPathAsset.pathName, localPathAsset.pathID],
          );
        } else {
          await db.insert(
            "device_path_collections",
            {
              "id": localPathAsset.pathID,
              "name": localPathAsset.pathName,
              "sync": autoSync ? _sqlBoolTrue : _sqlBoolFalse
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      // add the mappings for localIDs
      if (pathIDToLocalIDsMap.isNotEmpty) {
        debugPrint("Insert pathToLocalIDs mapping while importing localAssets");
        await insertPathIDToLocalIDMapping(
          pathIDToLocalIDsMap,
          conflictAlgorithm: ConflictAlgorithm.ignore, // do not reset sync
          // status
        );
      }
    } catch (e) {
      _logger.severe("failed to save path names", e);
      rethrow;
    }
  }

  Future<bool> updateDeviceCoverWithCount(
    List<Tuple2<AssetPathEntity, String>> devicePathInfo, {
    bool autoSync = false,
  }) async {
    bool hasUpdated = false;
    try {
      final Database db = await database;
      final Set<String> existingPathIds = await getDevicePathIDs();
      for (Tuple2<AssetPathEntity, String> tup in devicePathInfo) {
        AssetPathEntity pathEntity = tup.item1;
        String localID = tup.item2;
        bool shouldUpdate = existingPathIds.contains(pathEntity.id);
        if (shouldUpdate) {
          await db.rawUpdate(
            "UPDATE device_path_collections SET name = ?, cover_id = ?, count"
            " = ? where id = ?",
            [pathEntity.name, localID, pathEntity.assetCount, pathEntity.id],
          );
        } else {
          hasUpdated = true;
          await db.insert(
            "device_path_collections",
            {
              "id": pathEntity.id,
              "name": pathEntity.name,
              "count": pathEntity.assetCount,
              "cover_id": localID,
              "sync": autoSync ? _sqlBoolTrue : _sqlBoolFalse
            },
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
            "device_path_collections",
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

  Future<void> updateDevicePathSyncStatus(Map<String, bool> syncStatus) async {
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (MapEntry e in syncStatus.entries) {
      String pathID = e.key;
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.update(
        "device_path_collections",
        {
          "sync": e.value ? _sqlBoolTrue : _sqlBoolFalse,
        },
        where: 'id = ?',
        whereArgs: [pathID],
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateDevicePathCollection(
    String pathID,
    int collectionID,
  ) async {
    final db = await database;
    await db.update(
      "device_path_collections",
      {"collection_id": collectionID},
      where: 'id = ?',
      whereArgs: [pathID],
    );
    return;
  }

  Future<FileLoadResult> getFilesInDevicePathCollection(
    DevicePathCollection devicePathCollection,
    int startTime,
    int endTime, {
    int limit,
    bool asc,
  }) async {
    final db = await database;
    final order = (asc ?? false ? 'ASC' : 'DESC');
    String rawQuery = '''
    SELECT *
          FROM ${FilesDB.filesTable}
          WHERE ${FilesDB.columnLocalID} IS NOT NULL AND
          ${FilesDB.columnCreationTime} >= $startTime AND 
          ${FilesDB.columnCreationTime} <= $endTime AND 
          ${FilesDB.columnLocalID} IN 
          (SELECT id FROM device_files where path_id = '${devicePathCollection.id}' ) 
          ORDER BY ${FilesDB.columnCreationTime} $order , ${FilesDB.columnModificationTime} $order
         ''' +
        (limit != null ? ' limit $limit;' : ';');
    final results = await db.rawQuery(rawQuery);
    final files = convertToFiles(results);
    return FileLoadResult(files, files.length == limit);
  }

  Future<List<DevicePathCollection>> getDevicePathCollections() async {
    debugPrint("Fetching DevicePathCollections From DB");
    try {
      final db = await database;
      final fileRows = await db.rawQuery(
        '''SELECT * FROM FILES where local_id in (select cover_id from device_path_collections) group by local_id;
          ''',
      );
      final files = convertToFiles(fileRows);
      final devicePathRows = await db.rawQuery(
        '''SELECT * from device_path_collections''',
      );
      final List<DevicePathCollection> deviceCollections = [];
      for (var row in devicePathRows) {
        DevicePathCollection devicePathCollection = DevicePathCollection(
          row["id"],
          row['name'],
          count: row['count'],
          collectionID: row["collection_id"],
          coverId: row["cover_id"],
          sync: (row["sync"] ?? _sqlBoolFalse) == _sqlBoolTrue,
        );
        devicePathCollection.thumbnail = files.firstWhere(
          (element) => element.localID == devicePathCollection.coverId,
          orElse: () => null,
        );
        deviceCollections.add(devicePathCollection);
      }
      return deviceCollections;
    } catch (e) {
      _logger.severe('Failed to getDevicePathCollections', e);
      rethrow;
    }
  }
}
