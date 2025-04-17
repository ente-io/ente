import "package:photos/db/remote/db.dart";

extension CollectionFileRead on RemoteDB {
  Future<int> getCollectionFileCount(int collectionID) async {
    final row = await sqliteDB.get(
      "SELECT COUNT(*) as count FROM collection_files WHERE collection_id = ?",
      [collectionID],
    );
    return row["count"] as int;
  }
}
