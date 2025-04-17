import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/upload_strategy.dart';
import 'package:sqflite/sqlite_api.dart';

extension DeviceFiles on FilesDB {
  static final Logger _logger = Logger("DeviceFilesDB");
  static const _sqlBoolTrue = 1;
  static const _sqlBoolFalse = 0;

  Future<Map<String, int>> getDevicePathIDToImportedFileCount() async {
    try {
      final db = await sqliteAsyncDB;
      final rows = await db.getAll(
        '''
      SELECT count(*) as count, path_id
      FROM device_files
      GROUP BY path_id
    ''',
      );
      final result = <String, int>{};
      for (final row in rows) {
        result[row['path_id'] as String] = row["count"] as int;
      }
      return result;
    } catch (e) {
      _logger.severe("failed to getDevicePathIDToImportedFileCount", e);
      rethrow;
    }
  }

  Future<Map<String, Set<String>>> getDevicePathIDToLocalIDMap() async {
    try {
      final db = await sqliteAsyncDB;
      final rows = await db.getAll(
        ''' SELECT id, path_id FROM device_files; ''',
      );
      final result = <String, Set<String>>{};
      for (final row in rows) {
        final String pathID = row['path_id'] as String;
        if (!result.containsKey(pathID)) {
          result[pathID] = <String>{};
        }
        result[pathID]!.add(row['id'] as String);
      }
      return result;
    } catch (e) {
      _logger.severe("failed to getDevicePathIDToLocalIDMap", e);
      rethrow;
    }
  }

  // getDeviceSyncCollectionIDs returns the collectionIDs for the
  // deviceCollections which are marked for auto-backup
  Future<Set<int>> getDeviceSyncCollectionIDs() async {
    final db = await sqliteAsyncDB;
    final rows = await db.getAll(
      '''
      SELECT collection_id FROM device_collections where should_backup = 
      $_sqlBoolTrue 
      and collection_id != -1;
      ''',
    );
    final Set<int> result = <int>{};
    for (final row in rows) {
      result.add(row['collection_id'] as int);
    }
    return result;
  }

  Future<void> updateDevicePathSyncStatus(
    Map<String, bool> syncStatus,
  ) async {
    final db = await sqliteAsyncDB;
    int batchCounter = 0;
    final parameterSets = <List<Object?>>[];
    for (MapEntry e in syncStatus.entries) {
      final String pathID = e.key;
      parameterSets.add([e.value ? _sqlBoolTrue : _sqlBoolFalse, pathID]);
      batchCounter++;

      if (batchCounter == 400) {
        await db.executeBatch(
          '''
          UPDATE device_collections SET should_backup = ? WHERE id = ?;
        ''',
          parameterSets,
        );
        parameterSets.clear();
        batchCounter = 0;
      }
    }

    await db.executeBatch(
      '''
          UPDATE device_collections SET should_backup = ? WHERE id = ?;
        ''',
      parameterSets,
    );
  }

  Future<void> updateDeviceCollection(
    String pathID,
    int collectionID,
  ) async {
    final db = await sqliteAsyncDB;
    await db.execute(
      '''
      UPDATE device_collections SET collection_id = ? WHERE id = ?;
    ''',
      [collectionID, pathID],
    );
    return;
  }

  Future<BackedUpFileIDs> getBackedUpForDeviceCollection(
    String pathID,
    int ownerID,
  ) async {
    final db = await sqliteAsyncDB;
    const String rawQuery = '''
    SELECT ${FilesDB.columnLocalID}, ${FilesDB.columnUploadedFileID}, 
    ${FilesDB.columnFileSize} 
    FROM ${FilesDB.filesTable}
          WHERE ${FilesDB.columnLocalID} IS NOT NULL AND
          (${FilesDB.columnOwnerID} IS NULL OR ${FilesDB.columnOwnerID} = ?)
          AND (${FilesDB.columnUploadedFileID} IS NOT NULL AND ${FilesDB.columnUploadedFileID} IS NOT -1)
          AND 
          ${FilesDB.columnLocalID} IN 
          (SELECT id FROM device_files where path_id = ?)
          ''';
    final results = await db.getAll(rawQuery, [ownerID, pathID]);
    final localIDs = <String>{};
    final uploadedIDs = <int>{};
    int localSize = 0;
    for (final result in results) {
      final String localID = result[FilesDB.columnLocalID] as String;
      final int? fileSize = result[FilesDB.columnFileSize] as int?;
      if (!localIDs.contains(localID) && fileSize != null) {
        localSize += fileSize;
      }
      localIDs.add(localID);
      uploadedIDs.add(result[FilesDB.columnUploadedFileID] as int);
    }
    return BackedUpFileIDs(localIDs.toList(), uploadedIDs.toList(), localSize);
  }

  Future<List<DeviceCollection>> getDeviceCollections({
    bool includeCoverThumbnail = false,
  }) async {
    debugPrint(
      "Fetching DeviceCollections From DB with thumbnail = "
      "$includeCoverThumbnail",
    );
    try {
      final db = await sqliteAsyncDB;
      final coverFiles = <EnteFile>[];
      if (includeCoverThumbnail) {
        final fileRows = await db.getAll(
          '''SELECT * FROM FILES where local_id in (select cover_id from device_collections) group by local_id;
          ''',
        );
        final files = convertToFiles(fileRows);
        coverFiles.addAll(files);
      }
      final deviceCollectionRows = await db.getAll(
        '''SELECT * from device_collections''',
      );
      final List<DeviceCollection> deviceCollections = [];
      for (var row in deviceCollectionRows) {
        final DeviceCollection deviceCollection = DeviceCollection(
          row["id"] as String,
          (row['name'] ?? '') as String,
          count: row['count'] as int,
          collectionID: (row["collection_id"] ?? -1) as int,
          coverId: row["cover_id"] as String?,
          shouldBackup: (row["should_backup"] ?? _sqlBoolFalse) == _sqlBoolTrue,
          uploadStrategy: getUploadType((row["upload_strategy"] ?? 0) as int),
        );
        if (includeCoverThumbnail) {
          deviceCollection.thumbnail = coverFiles.firstWhereOrNull(
            (element) => element.localID == deviceCollection.coverId,
          );
          if (deviceCollection.thumbnail == null) {
            final EnteFile? result =
                await getDeviceCollectionThumbnail(deviceCollection.id);
            if (result == null) {
              _logger.finest(
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
              b.thumbnail!.creationTime!.compareTo(a.thumbnail!.creationTime!),
        );
      }
      return deviceCollections;
    } catch (e) {
      _logger.severe('Failed to getDeviceCollections', e);
      rethrow;
    }
  }

  Future<EnteFile?> getDeviceCollectionThumbnail(String pathID) async {
    debugPrint("Call fallback method to get potential thumbnail");
    final db = await sqliteAsyncDB;
    final fileRows = await db.getAll(
      '''SELECT * FROM FILES  f JOIN device_files df on f.local_id = df.id 
      and df.path_id= ? order by f.creation_time DESC limit 1;
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

  Future<void> _insertBatch(
    List<List<Object?>> parameterSets,
    ConflictAlgorithm conflictAlgorithm,
  ) async {
    final db = await sqliteAsyncDB;
    await db.executeBatch(
      '''
        INSERT OR ${conflictAlgorithm.name.toUpperCase()}
        INTO device_files (id, path_id) VALUES (?, ?);
      ''',
      parameterSets,
    );
  }

  Future<void> _deleteBatch(List<List<Object?>> parameterSets) async {
    final db = await sqliteAsyncDB;
    await db.executeBatch(
      '''
        DELETE FROM device_files WHERE id = ? AND path_id = ?;
      ''',
      parameterSets,
    );
  }
}
