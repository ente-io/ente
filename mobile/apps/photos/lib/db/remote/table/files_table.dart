import "package:photos/db/remote/db.dart";

extension FilesTable on RemoteDB {
  // For a given userID, return unique uploadedFileId for the given userID
  Future<List<int>> fileIDsWithMissingSize(int userId) async {
    final rows = await sqliteDB.getAll(
      "SELECT id FROM files WHERE owner_id = ? AND size = -1",
      [userId],
    );
    final result = <int>[];
    for (final row in rows) {
      result.add(row['id'] as int);
    }
    return result;
  }

  Future<Map<int, int>> getIDToCreationTime() async {
    final rows = await sqliteDB.getAll(
      "SELECT id, creation_time FROM files",
    );
    final result = <int, int>{};
    for (final row in rows) {
      result[row['id'] as int] = row['creation_time'] as int;
    }
    return result;
  }

  // updateSizeForUploadIDs takes a map of upploadedFileID and fileSize and
  // update the fileSize for the given uploadedFileID
  Future<void> updateSize(
    Map<int, int> idToSize,
  ) async {
    final parameterSets = <List<Object?>>[];
    for (final id in idToSize.keys) {
      parameterSets.add([idToSize[id], id]);
    }
    return sqliteDB.executeBatch(
      "UPDATE files SET size = ? WHERE id = ?;",
      parameterSets,
    );
  }
}
