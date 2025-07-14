import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:photos/db/remote/db.dart";
import "package:photos/db/remote/mappers.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/models/file/remote/rl_mapping.dart";

extension UploadMappingTable on RemoteDB {
  Future<void> insertMappings(List<RLMapping> mappings) async {
    if (mappings.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(mappings.slices(1000), (slice) async {
      final List<List<Object?>> values = slice.map((e) => e.rowValues).toList();
      await sqliteDB.executeBatch(
        'INSERT INTO upload_mapping ($uploadLocalMappingColumns) values(?,?,?,?)',
        values,
      );
    });
    debugPrint(
      '$runtimeType insertMappings complete in ${stopwatch.elapsed.inMilliseconds}ms for ${mappings.length} mappings',
    );
  }

  Future<List<RLMapping>> getMappings() async {
    final result = <RLMapping>[];
    final cursor = await sqliteDB.getAll("SELECT * FROM upload_mapping");
    for (final row in cursor) {
      result.add(rowToUploadLocalMapping(row));
    }
    return result;
  }

  Future<Map<String, RLMapping>> getLocalIDToMappingForActiveFiles() async {
    final result = <String, RLMapping>{};
    final cursor = await sqliteDB.getAll(
      "SELECT * FROM upload_mapping join files on upload_mapping.file_id = files.id",
    );
    for (final row in cursor) {
      final mapping = rowToUploadLocalMapping(row);
      result[mapping.localID] = mapping;
    }
    return result;
  }

  Future<Set<String>> getLocalIDsWithMapping(List<String> localIDs) async {
    if (localIDs.isEmpty) return {};
    final placeholders = List.filled(localIDs.length, '?').join(',');
    final cursor = await sqliteDB.getAll(
      'SELECT local_id FROM upload_mapping join files on upload_mapping.file_id = files.id WHERE local_id IN ($placeholders)',
      localIDs,
    );
    return cursor.map((row) => row['local_id'] as String).toSet();
  }

  Future<Map<int, String>> getFileIDToLocalIDMapping(List<int> fileIDs) async {
    if (fileIDs.isEmpty) return {};
    final placeholders = List.filled(fileIDs.length, '?').join(',');
    final cursor = await sqliteDB.getAll(
      'SELECT file_id, local_id FROM upload_mapping WHERE file_id IN ($placeholders)',
      fileIDs,
    );
    return Map.fromEntries(
      cursor.map(
        (row) => MapEntry(row['file_id'] as int, row['local_id'] as String),
      ),
    );
  }

  Future<Set<int>> getFilesWithMapping(List<int> fileIDs) async {
    if (fileIDs.isEmpty) return {};
    final placeholders = List.filled(fileIDs.length, '?').join(',');
    final cursor = await sqliteDB.getAll(
      'SELECT file_id FROM upload_mapping WHERE file_id IN ($placeholders)',
      fileIDs,
    );
    return cursor.map((row) => row['file_id'] as int).toSet();
  }
}
