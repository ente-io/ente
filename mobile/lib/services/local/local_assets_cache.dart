import "package:photo_manager/photo_manager.dart";

class LocalAssetsCache {
  final Map<String, AssetPathEntity> assetPaths;
  final Map<String, AssetEntity> assets;
  final Map<String, Set<String>> pathToAssetIDs;

  LocalAssetsCache({
    required this.assetPaths,
    required this.assets,
    required this.pathToAssetIDs,
  });
}
