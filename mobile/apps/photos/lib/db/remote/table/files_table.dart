import "package:photos/db/remote/db.dart";
import "package:photos/models/api/diff/diff.dart";

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

  Future<Map<int, List<(int, Metadata?)>>> getNotificationCandidate(
    List<int> collectionIDs,
    int lastAppOpen,
  ) async {
    if (collectionIDs.isEmpty) return {};
    final placeholders = List.filled(collectionIDs.length, '?').join(',');
    final rows = await sqliteDB.getAll(
      "SELECT  collection_id, files.owner_id, metadata FROM collection_files join files ON collection_files.file_id = files.id  WHERE collection_id IN ($placeholders) AND collection_files.created_at > ?",
      [...collectionIDs, lastAppOpen],
    );
    final result = <int, List<(int, Metadata?)>>{};
    for (final row in rows) {
      final collectionID = row['collection_id'] as int;
      final ownerID = row['owner_id'] as int;
      final metadata = Metadata.fromEncodedJson(row['metadata']);
      result.putIfAbsent(collectionID, () => []).add((ownerID, metadata));
    }
    return result;
  }
}
