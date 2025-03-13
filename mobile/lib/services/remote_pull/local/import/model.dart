import "package:photo_manager/photo_manager.dart";

class LocalPathAssets {
  final AssetPathEntity path;
  final List<AssetEntity> assets;

  LocalPathAssets({required this.path, required this.assets});
}

class LocalDiffResult {
  // List of assets that are present on device but missing in app.
  // unique on the basis of assetEntity.id
  final List<AssetEntity>? missingAssetsInApp;
  // Set of ids that are present inside app, but missing on the device
  final Set<String> extraAssetIDsInApp;

  final Set<String> extraPathIDsInApp;
  // map of path to localIDs which needs to be updated in the local db
  // the localIDs contains list of all assets that are present in the device's path
  final Map<String, Set<String>> updatePathToLocalIDs;

  LocalDiffResult({
    this.missingAssetsInApp,
    this.extraAssetIDsInApp = const {},
    this.updatePathToLocalIDs = const {},
    this.extraPathIDsInApp = const {},
  });
}
