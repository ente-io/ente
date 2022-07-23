import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
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
}
