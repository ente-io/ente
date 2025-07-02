import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:photos/db/remote/db.dart";
import "package:photos/db/remote/mappers.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file.dart";

extension TrashTable on RemoteDB {
  Future<void> insertTrashDiffItems(List<DiffItem> items) async {
    if (items.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await Future.forEach(items.slices(1000), (slice) async {
      final List<List<Object?>> trashRowValues = [];
      for (final item in slice) {
        trashRowValues.add(item.trashRowValues());
      }
      await Future.wait([
        sqliteDB.executeBatch(
          'INSERT INTO trash ($trashedFilesColumns) values(${getParams(14)})',
          trashRowValues,
        ),
      ]);
    });
    debugPrint(
      '$runtimeType insertCollectionFilesDiff complete in ${stopwatch.elapsed.inMilliseconds}ms for ${items.length}',
    );
  }

  // removes the items and returns the number of items removed
  Future<int> removeTrashItems(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final result = await sqliteDB.execute(
      'DELETE FROM trash WHERE id IN (${ids.join(",")})',
    );
    return result.isNotEmpty ? result.first['changes'] as int : 0;
  }

  Future<List<EnteFile>> getTrashFiles() async {
    final result = await sqliteDB.getAll(
      'SELECT * FROM trash',
    );
    return result.map((e) => trashRowToEnteFile(e)).toList();
  }

  Future<void> clearTrash() async {
    await sqliteDB.execute('DELETE FROM trash');
  }
}
