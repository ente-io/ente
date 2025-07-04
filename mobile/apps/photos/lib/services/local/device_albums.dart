import "package:photos/models/device_collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/local/import/local_import.dart";

extension DeviceAlbums on LocalImportService {
  Future<List<DeviceCollection>> getDeviceCollections() async {
    final cache = await getLocalAssetsCache();
    final pathToLatestAsset = cache.getPathToLatestAsset();
    final List<DeviceCollection> collections = [];
    for (final path in cache.assetPaths.values) {
      final asset = pathToLatestAsset[path.id];
      if (asset != null) {
        collections.add(
          DeviceCollection(
            path.id,
            path.name,
            count: cache.pathToAssetIDs[path.id]?.length ?? 0,
            thumbnail: asset,
          ),
        );
      }
    }
    return collections;
  }

  Future<List<EnteFile>> getAlbumFiles(String pathID) async {
    return localDB.getPathAssets(pathID);
  }
}
