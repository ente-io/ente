import "package:photos/db/remote/db.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/remote/file_entry.dart";

extension CollectionFiles on RemoteDB {
  Future<int> getCollectionFileCount(int collectionID) async {
    final row = await sqliteDB.get(
      "SELECT COUNT(*) as count FROM collection_files WHERE collection_id = ?",
      [collectionID],
    );
    return row["count"] as int;
  }

  Future<Set<int>> getUploadedFileIDs(int collectionID) async {
    final rows = await sqliteDB.getAll(
      "SELECT file_id FROM collection_files WHERE collection_id = ?",
      [collectionID],
    );
    final Set<int> fileIDs = {};
    for (var row in rows) {
      fileIDs.add(row["file_id"] as int);
    }
    return fileIDs;
  }

  Future<Set<int>> getAllCollectionIDsOfFile(int fileID) async {
    final rows = await sqliteDB.getAll(
      "SELECT collection_id FROM collection_files WHERE file_id = ?",
      [fileID],
    );
    return rows.map((row) => row["collection_id"] as int).toSet();
  }

  Future<Map<int, int>> getCollectionIdToFileCount(List<int> fileIDs) async {
    final rows = await sqliteDB.getAll(
      "SELECT collection_id, COUNT(*) as count FROM collection_files WHERE file_id IN (${fileIDs.join(",")}) GROUP BY collection_id",
    );
    final Map<int, int> collectionIdToFileCount = {};
    for (var row in rows) {
      final collectionId = row["collection_id"] as int;
      final count = row["count"] as int;
      collectionIdToFileCount[collectionId] = count;
    }
    return collectionIdToFileCount;
  }

  Future<List<CollectionFileEntry>> getCollectionFiles(
    FilterQueryParam? params,
  ) async {
    final rows = await sqliteDB.getAll(
      "SELECT * FROM collection_files  JOIN files on collection_files.file_id=files.id WHERE ${params?.whereClause() ?? "order by creation_time desc"}",
    );
    return rows
        .map((row) => CollectionFileEntry.fromMap(row))
        .toList(growable: false);
  }

  Future<CollectionFileEntry?> coverFile(
    int collectionID,
    int? fileID, {
    bool sortInAsc = false,
  }) async {
    if (fileID != null) {
      final entry = await getCollectionFileEntry(collectionID, fileID);
      if (entry != null) {
        return entry;
      }
    }
    final sortedRow = await sqliteDB.getOptional(
      "SELECT * FROM collection_files join files on files.id= collection_files.file_id WHERE collection_id = ? ORDER BY files.creation_time ${sortInAsc ? 'ASC' : 'DESC'} LIMIT 1",
      [collectionID],
    );
    if (sortedRow != null) {
      return CollectionFileEntry.fromMap(sortedRow);
    }

    return null;
  }

  Future<CollectionFileEntry?> getCollectionFileEntry(
    int collectionID,
    int fileID,
  ) async {
    final row = await sqliteDB.getOptional(
      "SELECT * FROM collection_files WHERE collection_id = ? AND file_id = ?",
      [collectionID, fileID],
    );
    if (row != null) {
      return CollectionFileEntry.fromMap(row);
    }
    return null;
  }

  Future<CollectionFileEntry?> getAnyCollectionEntry(
    int fileID,
  ) async {
    final row = await sqliteDB.getAll(
      "SELECT * FROM collection_files WHERE file_id = ? limit 1",
      [fileID],
    );
    if (row.isNotEmpty) {
      return CollectionFileEntry.fromMap(row.first);
    }
    return null;
  }

  Future<Map<int, int>> getCollectionIDToMaxCreationTime() async {
    final enteWatch = EnteWatch("getCollectionIDToMaxCreationTime")..start();
    final rows = await sqliteDB.getAll(
      '''SELECT collection_id, MAX(creation_time) as max_creation_time FROM collection_files join files on 
      collection_files.file_id=files.id  GROUP BY collection_id''',
    );
    final Map<int, int> result = {};
    for (var row in rows) {
      final collectionId = row["collection_id"] as int;
      final maxCreationTime = row["max_creation_time"] as int;
      result[collectionId] = maxCreationTime;
    }
    enteWatch.log("query done");
    return result;
  }
}
