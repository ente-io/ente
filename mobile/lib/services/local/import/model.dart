import "package:photo_manager/photo_manager.dart";

class DevicePathAssets {
  final AssetPathEntity path;
  final List<AssetEntity> assets;
  DevicePathAssets({required this.path, required this.assets});
}

class IncrementalDiffReqParams {
  final List<DevicePathAssets> newOrUpdatedLocalPaths;
  final Set<String> inAppAssetIDs;
  final int fromTimeInMs;
  final int toTimeInMs;

  IncrementalDiffReqParams(
    this.newOrUpdatedLocalPaths,
    this.inAppAssetIDs,
    this.fromTimeInMs,
    this.toTimeInMs,
  );
}

// IncrementalDiffWithOnDevice provides the diff between
// the assets present in the app and
// the new assets added or modified on the device after certain time.
class IncrementalDiffWithOnDevice {
  final List<AssetPathEntity> addedOrModifiedPaths;
  final Map<String, Set<String>> newOrUpdatedPathToLocalIDs;
  // unique on the basis of assetEntity.id
  final List<AssetEntity> assets;
  // assets that were already imported in the, but are potentially updated
  final Set<String> updatedAssetIds;

  IncrementalDiffWithOnDevice(
    this.addedOrModifiedPaths,
    this.newOrUpdatedPathToLocalIDs,
    this.assets,
    this.updatedAssetIds,
  );
}

class FullDiffReqParams {
  final List<DevicePathAssets> allOnDeviceAssets;
  final Set<String> inAppAssetIDs;
  final Map<String, Set<String>> inAppPathToLocalIDs;

  FullDiffReqParams(
    this.allOnDeviceAssets,
    this.inAppAssetIDs,
    this.inAppPathToLocalIDs,
  );
}

// DiffWithOnDevice provides the diff between the assets present in the app and all the assets present on the device.
class FullDiffWithOnDevice {
  // List of assets that are present on device but missing in app.
  // unique on the basis of assetEntity.id
  final List<AssetEntity> missingAssetsInApp;
  // Set of ids that are present inside app, but missing on the device.
  // We should remove these assets from the app.
  final Set<String> extraAssetIDsInApp;

  // Set of path ids that are present inside app, but missing on the device.
  // We should remove these paths from the app.
  final Set<String> extraPathIDsInApp;

  // map of path to localIDs which needs to be updated in the local db
  // the localIDs contains list of all assets that are present in the device's path.
  // We should delete existing mapping for these paths and insert the new mapping.
  final Map<String, Set<String>> updatePathToLocalIDs;

  FullDiffWithOnDevice({
    this.missingAssetsInApp = const [],
    this.extraAssetIDsInApp = const {},
    this.updatePathToLocalIDs = const {},
    this.extraPathIDsInApp = const {},
  });

  bool get isInOutOfSync =>
      missingAssetsInApp.isNotEmpty ||
      extraAssetIDsInApp.isNotEmpty ||
      updatePathToLocalIDs.isNotEmpty ||
      extraPathIDsInApp.isNotEmpty;

  String countLog() {
    return "missingAssetsInApp: ${missingAssetsInApp.length}, extraAssetIDsInApp: ${extraAssetIDsInApp.length}, updatePathToLocalIDs: ${updatePathToLocalIDs.length}, extraPathIDsInApp: ${extraPathIDsInApp.length}";
  }
}
