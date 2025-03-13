import "package:computer/computer.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/services/remote_pull/local/import/model.dart";

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

Future<LocalDiffResult> getDiffFromExistingImport(
  List<LocalPathAssets> allOnDeviceAssets,
  // current set of assets available on device
  Set<String> inAppAssetIDs, // localIDs of files already imported in app
  Map<String, Set<String>> inAppPathToLocalIDs,
) async {
  final Map<String, dynamic> args = <String, dynamic>{};
  args['allOnDeviceAssets'] = allOnDeviceAssets;
  args['inAppAssetIDs'] = inAppAssetIDs;
  args['inAppPathToLocalIDs'] = inAppPathToLocalIDs;
  final LocalDiffResult diffResult = await Computer.shared().compute(
    _getLocalAssetsDiff,
    param: args,
    taskName: "getLocalAssetsDiff",
  );
  return diffResult;
}

// _getLocalAssetsDiff compares local db with the file system and compute
// the files which needs to be added or removed from device collection.
LocalDiffResult _getLocalAssetsDiff(Map<String, dynamic> args) {
  final List<LocalPathAssets> onDeviceLocalPathAsset =
      args['allOnDeviceAssets'];
  final Set<String> inAppAssetIDs = args['inAppAssetIDs'];
  final Map<String, Set<String>> inAppPathToLocalIDs =
      args['inAppPathToLocalIDs'];

  // Step 1: Build onDevicePathToLocalIDs and missingAssetsInApp
  final Set<String> onDeviceAssetIDs = {};
  final Map<String, Set<String>> onDevicePathToLocalIDs = {};
  final Map<String, AssetEntity> uniqueMissingAssetsInApp = {};

  for (var diff in onDeviceLocalPathAsset) {
    final String pathID = diff.path.id;
    final Set<String> localIDs = {};
    for (var asset in diff.assets) {
      localIDs.add(asset.id);
      onDeviceAssetIDs.add(asset.id);
      // Track missing assets uniquely by id
      if (!inAppAssetIDs.contains(asset.id)) {
        uniqueMissingAssetsInApp[asset.id] = asset;
      }
    }
    onDevicePathToLocalIDs[pathID] = localIDs;
  }

  final Set<String> extraAssetIDsInApp = {};
  final Set<String> extraPathIDsInApp = {};
  final Map<String, Set<String>> updatePathToLocalIDs = {};

  // Step 2: Find assets that exist in the app but not on device
  for (var assetID in inAppAssetIDs) {
    if (!onDeviceAssetIDs.contains(assetID)) {
      extraAssetIDsInApp.add(assetID);
    }
  }

  // Step 3: Find paths that exist in the app but not on device
  // and determine which paths need updates
  for (var entry in inAppPathToLocalIDs.entries) {
    final String pathID = entry.key;
    final Set<String> inAppLocalIDs = entry.value;

    if (!onDevicePathToLocalIDs.containsKey(pathID)) {
      // Path exists in app but not on device
      extraPathIDsInApp.add(pathID);
    } else {
      // Path exists in both, check if the assets differ
      final Set<String> onDeviceLocalIDs = onDevicePathToLocalIDs[pathID]!;

      // Simplified comparison: check if sets have same size and same elements
      if (inAppLocalIDs.length != onDeviceLocalIDs.length ||
          !inAppLocalIDs.containsAll(onDeviceLocalIDs)) {
        updatePathToLocalIDs[pathID] = onDeviceLocalIDs;
      }
    }
  }

  return LocalDiffResult(
    missingAssetsInApp: uniqueMissingAssetsInApp.values.toList(),
    extraAssetIDsInApp: extraAssetIDsInApp,
    extraPathIDsInApp: extraPathIDsInApp,
    updatePathToLocalIDs: updatePathToLocalIDs,
  );
}
