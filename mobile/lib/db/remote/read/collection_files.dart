import "package:photos/db/remote/db.dart";

extension CollectionFileRead on RemoteDB {
  Future<int> getCollectionFileCount(int collectionID) async {
    final row = await sqliteDB.get(
      "SELECT COUNT(*) as count FROM collection_files WHERE collection_id = ?",
      [collectionID],
    );
    return row["count"] as int;
  }

  Future<Set<int>> getAllCollectionIDsOfFile(int fileID) async {
    final rows = await sqliteDB.getAll(
      "SELECT collection_id FROM collection_files WHERE file_id = ?",
      [fileID],
    );
    return rows.map((row) => row["collection_id"] as int).toSet();
  }

  Future<Map<int, int>> getCollectionIdToFileCount(List<int> file_ids) async {
    final rows = await sqliteDB.getAll(
      "SELECT collection_id, COUNT(*) as count FROM collection_files WHERE file_id IN (${file_ids.join(",")}) GROUP BY collection_id",
    );
    final Map<int, int> collectionIdToFileCount = {};
    for (var row in rows) {
      final collectionId = row["collection_id"] as int;
      final count = row["count"] as int;
      collectionIdToFileCount[collectionId] = count;
    }
    return collectionIdToFileCount;
  }
}
