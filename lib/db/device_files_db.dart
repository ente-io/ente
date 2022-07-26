import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import 'package:sqflite/sqlite_api.dart';

extension DeviceFiles on FilesDB {
  static final Logger _logger = Logger("DeviceFilesDB");

  Future<void> insertDeviceFiles(List<File> files) async {
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
        conflictAlgorithm: ConflictAlgorithm.ignore,
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

  Future<Map<String, int>> getDevicePathIDToImportedFileCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT count(*) as count, path_id
      FROM device_path_collections
      GROUP BY path_id
    ''',
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[row['path_id']] = row["count"];
    }
    return result;
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

  Future<int> updateDeviceCoverWithCount(
    AssetPathEntity pathEntity,
    String localID,
  ) async {
    try {
      final Database db = await database;
      return db.rawUpdate(
        "UPDATE device_path_collections SET name = ?, cover_id = ?, count"
        " = ? where id = ?",
        [pathEntity.name, localID, pathEntity.assetCount, pathEntity.id],
      );
    } catch (e) {
      _logger.severe("failed to save path names", e);
      rethrow;
    }
  }
}
