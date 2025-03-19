import "package:photo_manager/photo_manager.dart";

class LocalAssetsCache {
  final Map<String, AssetPathEntity> _assetPaths;
  final Map<String, AssetEntity> _assets;
  final Map<String, Set<String>> _pathToAssetIDs;

  LocalAssetsCache({
    required Map<String, AssetPathEntity> assetPaths,
    required Map<String, AssetEntity> assets,
    required Map<String, Set<String>> pathToAssetIDs,
  })  : _assetPaths = assetPaths,
        _assets = assets,
        _pathToAssetIDs = pathToAssetIDs;
}
