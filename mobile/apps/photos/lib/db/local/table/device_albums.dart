import "package:photo_manager/photo_manager.dart";
import "package:photos/db/local/db.dart";
import "package:photos/db/local/mappers.dart";
import "package:photos/db/local/schema.dart";
import "package:photos/models/device_collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/upload_strategy.dart";

extension DeviceAlbums on LocalDB {
  Future<List<DeviceCollection>> getDeviceCollections() async {
    final List<DeviceCollection> collections = [];
    final rows = await sqliteDB.getAll(deviceCollectionWithOneAssetQuery);
    for (final row in rows) {
      final path = LocalDBMappers.assetPath(row);
      AssetEntity? asset;
      if (row['id'] != null) {
        asset = LocalDBMappers.asset(row);
      }
      collections.add(
        DeviceCollection(
          path,
          count: row['asset_count'] as int,
          thumbnail: asset != null ? EnteFile.fromAssetSync(asset) : null,
          shouldBackup: (row['should_backup'] as int) == 1,
          uploadStrategy: UploadStrategy.values[row['upload_strategy'] as int],
        ),
      );
    }

    return collections;
  }
}
