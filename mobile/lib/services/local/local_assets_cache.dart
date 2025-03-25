import "package:photo_manager/photo_manager.dart";
import "package:photos/services/local/import/model.dart";

class LocalAssetsCache {
  final Map<String, AssetPathEntity> assetPaths;
  final Map<String, AssetEntity> assets;
  final Map<String, Set<String>> pathToAssetIDs;

  LocalAssetsCache({
    required this.assetPaths,
    required this.assets,
    required this.pathToAssetIDs,
  });

  void updateForDiff({
    IncrementalDiffWithOnDevice? incrementalDiff,
    FullDiffWithOnDevice? fullDiff,
  }) {
    if (incrementalDiff != null) {
      for (final asset in incrementalDiff.assets) {
        assets[asset.id] = asset;
      }
      for (final path in incrementalDiff.addedOrModifiedPaths) {
        assetPaths[path.id] = path;
      }
      for (final entry in incrementalDiff.newOrUpdatedPathToLocalIDs.entries) {
        final Set<String> existing = pathToAssetIDs[entry.key] ?? {};
        pathToAssetIDs[entry.key] = existing..addAll(entry.value);
      }
    } else if (fullDiff != null) {
      for (final id in fullDiff.extraAssetIDsInApp) {
        assets.remove(id);
      }
      for (final id in fullDiff.extraPathIDsInApp) {
        assetPaths.remove(id);
      }
      for (final asset in fullDiff.missingAssetsInApp) {
        assets[asset.id] = asset;
      }
      for (final entry in fullDiff.updatePathToLocalIDs.entries) {
        // delete old mappings
        pathToAssetIDs[entry.key] = entry.value;
      }
    }
  }

  Map<String, AssetEntity> getPathToLatestAsset() {
    final Map<String, AssetEntity> pathToLatestAsset = {};
    for (final entry in pathToAssetIDs.entries) {
      AssetEntity? latestAsset;
      for (final id in entry.value) {
        final asset = assets[id];
        if (asset != null &&
            (latestAsset == null ||
                (asset.createDateSecond ?? 0) >
                    (latestAsset.createDateSecond ?? 0))) {
          latestAsset = asset;
        }
      }
      if (latestAsset != null) {
        pathToLatestAsset[entry.key] = latestAsset;
      }
    }
    return pathToLatestAsset;
  }
}
