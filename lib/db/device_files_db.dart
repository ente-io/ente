import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:tuple/tuple.dart';

extension DeviceFiles on FilesDB {
  static final Logger _logger = Logger("DeviceFilesDB");

  Future<void> insertDeviceFiles(
    List<File> files, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.ignore,
  }) async {
    final startTime = DateTime.now();
    final db = await database;
    var batch = db.batch();
    int batchCounter = 0;
    for (File file in files) {
      if (file.localID == null || file.devicePathID == null) {
        debugPrint(
          "attempting to insert file with missing local or "
          "devicePathID ${file.tag()}",
        );
        continue;
      }
      if (batchCounter == 400) {
        await batch.commit(noResult: true);
        batch = db.batch();
        batchCounter = 0;
      }
      batch.insert(
        "device_files",
        {
          "id": file.localID,
          "path_id": file.devicePathID,
        },
        conflictAlgorithm: conflictAlgorithm,
      );
      batchCounter++;
    }
    await batch.commit(noResult: true);
    final endTime = DateTime.now();
    final duration = Duration(
      microseconds:
          endTime.microsecondsSinceEpoch - startTime.microsecondsSinceEpoch,
    );
    _logger.info(
      "Batch insert of  ${files.length} took ${duration.inMilliseconds} ms.",
    );
  }

  Future<void> insertPathIDToLocalIDMapping(
    Map<String, Set<String>> mappingToAdd, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.ignore,
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
    final rows = await (await database).rawQuery(
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
  Future<void> insertOrUpdatePathName(
    List<AssetPathEntity> pathEntities,
  ) async {
    try {
      final Set<String> existingPathIds = await getDevicePathIDs();
      final Database db = await database;
      for (AssetPathEntity pathEntity in pathEntities) {
        if (existingPathIds.contains(pathEntity.id)) {
          await db.rawUpdate(
            "UPDATE device_path_collections SET name = ? where id = "
            "?",
            [pathEntity.name, pathEntity.id],
          );
        } else {
          await db.insert(
            "device_path_collections",
            {
              "id": pathEntity.id,
              "name": pathEntity.name,
            },
          );
        }
      }
    } catch (e) {
      _logger.severe("failed to save path names", e);
      rethrow;
    }
  }

  Future<bool> updateDeviceCoverWithCount(
    List<Tuple2<AssetPathEntity, File>> devicePathInfo,
  ) async {
    bool hasUpdated = false;
    try {
      final Database db = await database;
      final Set<String> existingPathIds = await getDevicePathIDs();
      for (Tuple2<AssetPathEntity, File> tup in devicePathInfo) {
        AssetPathEntity pathEntity = tup.item1;
        String localID = tup.item2.localID;
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
          ORDER BY ${FilesDB.columnCreationTime} $order , ${FilesDB.columnModificationTime} $order LIMIT $limit
         ''';
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
