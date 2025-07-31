import "package:flutter/foundation.dart";
import "package:photos/db/remote/db.dart";
import "package:photos/db/remote/schema.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/remote/collection_file.dart";

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
    return getAllCollectionIDsOfFile(fileID);
  }

  Future<List<CollectionFile>> getAllCFForFileIDs(
    List<int> fileIDs,
  ) async {
    final rows = await sqliteDB.getAll(
      "SELECT * FROM collection_files WHERE file_id IN (${fileIDs.join(",")})",
    );
    return rows
        .map((row) => CollectionFile.fromMap(row))
        .toList(growable: false);
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

  Future<List<CollectionFile>> getCollectionFiles(
    FilterQueryParam? params,
  ) async {
    final rows = await sqliteDB.getAll(
      "SELECT * FROM collection_files  JOIN files on collection_files.file_id=files.id WHERE ${params?.whereClause() ?? "order by creation_time desc"}",
    );
    return rows
        .map((row) => CollectionFile.fromMap(row))
        .toList(growable: false);
  }

  Future<List<CollectionFile>> getCollectionsFiles(
    Set<int> collectionIDs,
  ) async {
    final rows = await sqliteDB.getAll(
      "SELECT * FROM collection_files JOIN files on collection_files.file_id=files.id WHERE collection_id IN (${collectionIDs.join(",")}) ORDER BY creation_time DESC",
    );
    return rows
        .map((row) => CollectionFile.fromMap(row))
        .toList(growable: false);
  }

  Future<Map<int, CollectionFile>> getFileIdToCollectionFile(
    List<int> fileIDs,
  ) async {
    final rows = await sqliteDB.getAll(
      "SELECT * FROM collection_files JOIN files on collection_files.file_id=files.id WHERE file_id IN (${fileIDs.join(",")})",
    );
    final Map<int, CollectionFile> result = {};
    for (var row in rows) {
      final entry = CollectionFile.fromMap(row);
      result[entry.fileID] = entry;
    }
    return result;
  }

  Future<List<CollectionFile>> getAllFiles(int userID) {
    return sqliteDB.getAll(
      "SELECT * FROM collection_files JOIN files ON collection_files.file_id = files.id WHERE files.owner_id = ? ORDER BY files.creation_time DESC",
      [userID],
    ).then(
      (rows) => rows.map((row) => CollectionFile.fromMap(row)).toList(),
    );
  }

  Future<(Set<int>, Map<String, int>)> getUploadAndHash(
    int collectionID,
  ) async {
    final results = await sqliteDB.getAll(
      'SELECT id, hash FROM collection_files JOIN files ON files.id = collection_files.file_id'
      ' WHERE collection_id = ?',
      [
        collectionID,
      ],
    );
    final ids = <int>{};
    final hash = <String, int>{};
    for (final result in results) {
      ids.add(result['id'] as int);
      if (result['hash'] != null) {
        hash[result['hash'] as String] = result['id'] as int;
      }
    }
    return (ids, hash);
  }

  Future<List<CollectionFile>> ownedFilesWithSameHash(
    List<String> hashes,
    int ownerID,
  ) async {
    if (hashes.isEmpty) return [];
    final inParam = hashes.map((e) => "'$e'").join(',');
    final rows = await sqliteDB.getAll(
      "SELECT * FROM collection_files JOIN files ON collection_files.file_id = files.id WHERE files.hash IN ($inParam) AND files.owner_id = ?",
      [ownerID],
    );
    return rows
        .map((row) => CollectionFile.fromMap(row))
        .toList(growable: false);
  }

  Future<CollectionFile?> coverFile(
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
      return CollectionFile.fromMap(sortedRow);
    }

    return null;
  }

  Future<CollectionFile?> getCollectionFileEntry(
    int collectionID,
    int fileID,
  ) async {
    final row = await sqliteDB.getOptional(
      "SELECT * FROM collection_files WHERE collection_id = ? AND file_id = ?",
      [collectionID, fileID],
    );
    if (row != null) {
      return CollectionFile.fromMap(row);
    }
    return null;
  }

  Future<CollectionFile?> getAnyCollectionEntry(
    int fileID,
  ) async {
    final row = await sqliteDB.getAll(
      "SELECT * FROM collection_files WHERE file_id = ? limit 1",
      [fileID],
    );
    if (row.isNotEmpty) {
      return CollectionFile.fromMap(row.first);
    }
    return null;
  }

  Future<List<CollectionFile>> getFilesCreatedWithinDurations(
    List<List<int>> durations,
    Set<int> ignoredCollectionIDs, {
    String order = 'DESC',
  }) async {
    final List<CollectionFile> result = [];
    for (final duration in durations) {
      final start = duration[0];
      final end = duration[1];
      final rows = await sqliteDB.getAll(
        "SELECT * FROM collection_files join files on files.id=collection_files.file_id WHERE files.creation_time BETWEEN ? AND ? AND collection_id NOT IN (${ignoredCollectionIDs.join(",")}) ORDER BY creation_time $order",
        [start, end],
      );
      result.addAll(rows.map((row) => CollectionFile.fromMap(row)));
    }
    return result;
  }

  Future<List<CollectionFile>> filesWithLocation() {
    return sqliteDB
        .getAll(
          "SELECT * FROM collection_files JOIN files ON collection_files.file_id = files.id WHERE files.lat IS NOT NULL and files.lng IS NOT NULL order by files.creation_time desc",
        )
        .then(
          (rows) => rows.map((row) => CollectionFile.fromMap(row)).toList(),
        );
  }

  Future<void> deleteFiles(List<int> fileIDs) async {
    if (fileIDs.isEmpty) return;
    final stopwatch = Stopwatch()..start();
    await sqliteDB.execute(
      "DELETE FROM collection_files WHERE file_id IN (${fileIDs.join(",")})",
    );
    debugPrint(
      '$runtimeType deleteFiles complete in ${stopwatch.elapsed.inMilliseconds}ms for ${fileIDs.length}',
    );
  }

  Future<void> deleteCollectionFiles(List<int> cIDs) async {
    if (cIDs.isEmpty) return;
    await sqliteDB.execute(
      "DELETE FROM collection_files WHERE collection_id IN (${cIDs.join(",")})",
    );
  }

  Future<void> deleteCFEnteries(
    int collectionID,
    List<int> fileIDs,
  ) async {
    if (fileIDs.isEmpty) return;
    await sqliteDB.execute(
      "DELETE FROM collection_files WHERE collection_id = ? AND file_id IN (${fileIDs.join(",")})",
      [collectionID],
    );
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
