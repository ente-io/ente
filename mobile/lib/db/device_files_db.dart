import 'package:photos/db/files_db.dart';
import 'package:photos/models/backup_status.dart';

extension DeviceFiles on FilesDB {
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
}
