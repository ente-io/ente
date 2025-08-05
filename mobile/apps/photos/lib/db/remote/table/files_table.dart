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

  Future<Map<int, Metadata?>> getIDToMetadata(
    Set<int> ids, {
    bool private = false,
    bool public = false,
    bool metadata = false,
  }) async {
    if (ids.isEmpty) return {};

    // Ensure only one parameter is true
    final trueCount = [private, public, metadata].where((x) => x).length;
    if (trueCount != 1) {
      throw ArgumentError(
        'Exactly one of private, public, or metadata must be true',
      );
    }

    final placeholders = List.filled(ids.length, '?').join(',');
    String column;

    if (private) {
      column = 'priv_metadata';
    } else if (public) {
      column = 'pub_metadata';
    } else {
      column = 'metadata';
    }
    final rows = await sqliteDB.getAll(
      "SELECT id, $column FROM files_metadata WHERE id IN ($placeholders)",
      ids.toList(),
    );
    final result = <int, Metadata?>{};
    for (final row in rows) {
      final metadata = Metadata.fromEncodedJson(row[column]);
      result[row['id'] as int] = metadata;
    }
    return result;
  }

  Future<Set<int>> idsWithSameHashAndType(String hash, int ownerID) {
    return sqliteDB.getAll(
      "SELECT id FROM files WHERE hash = ? AND owner_id = ?",
      [hash, ownerID],
    ).then((rows) {
      final result = <int>{};
      for (final row in rows) {
        result.add(row['id'] as int);
      }
      return result;
    });
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

  Future<int> getFilesCountByVisibility(
    int visibility,
    int ownerID,
    Set<int> hiddenCollections,
  ) async {
    String subQuery = '';
    if (hiddenCollections.isNotEmpty) {
      subQuery =
          'AND id NOT IN (SELECT file_id FROM collection_files WHERE collection_id IN (${hiddenCollections.join(',')}))';
    }
    final row = await sqliteDB.get(
      'SELECT COUNT(id) as count FROM files WHERE visibility = ? AND owner_id = ? $subQuery',
      [visibility, ownerID],
    );
    return row['count'] as int;
  }
}
