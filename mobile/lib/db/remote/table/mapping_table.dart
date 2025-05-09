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
}
