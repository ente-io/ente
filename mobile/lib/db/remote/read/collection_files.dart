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
}
