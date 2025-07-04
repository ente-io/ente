import "package:collection/collection.dart";
import "package:photos/db/local/db.dart";
import "package:photos/models/local/shared_asset.dart";

extension SharedAssetsTable on LocalDB {
  Future<Set<String>> getSharedAssetsID() async {
    final result = await sqliteDB.getAll('SELECT id FROM shared_assets');
    return Set.unmodifiable(result.map<String>((row) => row['id'] as String));
  }

  Future<void> insertSharedAssets(List<SharedAsset> assets) async {
    if (assets.isEmpty) return;
    await Future.forEach(
      assets.slices(LocalDB.batchInsertMaxCount),
      (slice) async {
        final List<List<Object?>> values =
            slice.map((e) => e.rowProps).toList();
        await sqliteDB.executeBatch(
          'INSERT INTO shared_assets (id, name, type, creation_time, duration_in_seconds, dest_collection_id, owner_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
          values,
        );
      },
    );
  }

  Future<List<SharedAsset>> getSharedAssets() async {
    final result = await sqliteDB.getAll(
      'SELECT * FROM shared_assets ORDER BY creation_time DESC',
    );
    return result.map((row) => SharedAsset.fromRow(row)).toList();
  }

  Future<List<SharedAsset>> getSharedAssetsByCollection(
    int collectionID,
  ) async {
    final result = await sqliteDB.getAll(
      'SELECT * FROM shared_assets WHERE dest_collection_id = ? ORDER BY creation_time DESC',
      [collectionID],
    );
    return result.map((row) => SharedAsset.fromRow(row)).toList();
  }

  Future<void> deleteSharedAssetsByCollection(int collectionID) async {
    await sqliteDB.execute(
      'DELETE FROM shared_assets WHERE dest_collection_id = ?',
      [collectionID],
    );
  }

  Future<void> deleteSharedAsset(String assetID) async {
    await sqliteDB.execute(
      'DELETE FROM shared_assets WHERE id = ?',
      [assetID],
    );
  }
}
