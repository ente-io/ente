import 'dart:io';
import 'dart:math';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_import_progress.dart';
import "package:photos/extensions/stop_watch.dart";
import "package:photos/services/local/import/model.dart";

class DeviceAssetsService {
  final _logger = Logger("DeviceAssetsService");
  // The ignoreSizeConstraint is used to ignore the size constraint, otherwise
  // photo manager will only give assets that meet it's default constraint where
  // only assets with w/h in [0,100000] dim will be returned
  static const ignoreSizeConstraint = SizeConstraint(ignoreSize: true);
  static const assetFetchPageSize = 2000;

  Future<IncrementalDiffWithOnDevice> incrementalDiffWithOnDevice(
    Set<String> inAppAssetIDs,
    TimeLogger tL, {
    required int fromTimeInMs,
    required int toTimeInMs,
  }) async {
    final newOrUpdatedDevicePaths = await _getDevicePathAssets(
      fromTimeInMs: fromTimeInMs,
      toTimeInMs: toTimeInMs,
    );
    final logMsg =
        "fetched devicePathDiff (${newOrUpdatedDevicePaths.length}) $tL";
    final result = Computer.shared()
        .compute<IncrementalDiffReqParams, IncrementalDiffWithOnDevice>(
      _computeIncrementalDiffWithOnDevice,
      param: IncrementalDiffReqParams(
        newOrUpdatedDevicePaths,
        inAppAssetIDs,
        fromTimeInMs,
        toTimeInMs,
      ),
      taskName: "computeIncrementalDiffWithOnDevice",
    );
    _logger.info('$logMsg, computed diff $tL');
    return result;
  }

  Future<FullDiffWithOnDevice> fullDiffWithOnDevice(
    Set<String> inAppAssetIDs, // localIDs of files already imported in app
    Map<String, Set<String>> inAppPathToLocalIDs,
    TimeLogger tL,
  ) async {
    final allOnDeviceAssets = await _getDevicePathAssets();
    final String logMsg = "fetched allDeviceAssets $tL";
    final r = await Computer.shared()
        .compute<FullDiffReqParams, FullDiffWithOnDevice>(
      _computeFullDiffWithOnDevice,
      param: FullDiffReqParams(
        allOnDeviceAssets,
        inAppAssetIDs,
        inAppPathToLocalIDs,
      ),
      taskName: "computeFullDiffWithOnDevice",
    );
    _logger.info('$logMsg, computed diff $tL');
    return r;
  }

  // _getAssetPaths will return AssetEntityPath and assets that will meet the
  // specified filter conditions. If fromTimeInMs and toTimeInMs are provided,
  // we will only get those assets that were updated in the specified time.
  Future<List<DevicePathAssets>> _getDevicePathAssets({
    int? fromTimeInMs,
    int? toTimeInMs,
  }) async {
    final List<AssetPathEntity> assetPaths = await _getDevicePaths(
      updateFromTimeInMs: fromTimeInMs,
      updateToTimeInMs: toTimeInMs,
    );
    final List<DevicePathAssets> localPathAssets = [];
    for (final assetPath in assetPaths) {
      final List<AssetEntity> assets = await _getPathAssetLists(assetPath);
      localPathAssets.add(
        DevicePathAssets(
          path: assetPath,
          assets: assets,
        ),
      );
    }
    return localPathAssets;
  }

  /// returns a list of AssetPathEntity with relevant filter operations.
  /// [needTitle] impacts the performance for fetching the actual [AssetEntity]
  /// in iOS. Same is true for [containsModifiedPath]
  Future<List<AssetPathEntity>> _getDevicePaths({
    final int? updateFromTimeInMs,
    final int? updateToTimeInMs,
    final bool containsModifiedPath = false,
    // in iOS fetching the AssetEntity title impacts performance
    final bool needsTitle = true,
    final OrderOption? orderOption,
  }) async {
    final filterOptionGroup = FilterOptionGroup();

    filterOptionGroup.setOption(
      AssetType.image,
      FilterOption(needTitle: needsTitle, sizeConstraint: ignoreSizeConstraint),
    );
    filterOptionGroup.setOption(
      AssetType.video,
      FilterOption(needTitle: needsTitle, sizeConstraint: ignoreSizeConstraint),
    );

    if (orderOption != null) {
      filterOptionGroup.addOrderOption(orderOption);
    }
    if (updateFromTimeInMs != null && updateToTimeInMs != null) {
      filterOptionGroup.updateTimeCond = DateTimeCond(
        min: DateTime.fromMillisecondsSinceEpoch(updateFromTimeInMs),
        max: DateTime.fromMillisecondsSinceEpoch(updateToTimeInMs),
      );
    } else {
      // During full diff, ignore the default creation time filter otherwise
      // photo manager will only give assets with creation time between [0, now()]
      // utc. This will cause the app to miss out on assets that have creation_time
      // outside this time window.
      filterOptionGroup.createTimeCond =
          DateTimeCond.def().copyWith(ignore: true);
    }
    filterOptionGroup.containsPathModified = containsModifiedPath;
    final galleryList = await PhotoManager.getAssetPathList(
      hasAll: !Platform.isAndroid,
      type: RequestType.common,
      filterOption: filterOptionGroup,
    );
    galleryList.sort((s1, s2) {
      if (s1.isAll) {
        return 1;
      }
      return 0;
    });

    return galleryList;
  }

  Future<List<AssetEntity>> _getPathAssetLists(
    AssetPathEntity pathEntity,
  ) async {
    final List<AssetEntity> result = [];
    int currentPage = 0;
    List<AssetEntity> currentPageResult = [];
    do {
      currentPageResult = await pathEntity.getAssetListPaged(
        page: currentPage,
        size: assetFetchPageSize,
      );
      Bus.instance.fire(
        LocalImportProgressEvent(
          pathEntity.name,
          currentPage * assetFetchPageSize + currentPageResult.length,
        ),
      );
      result.addAll(currentPageResult);
      currentPage = currentPage + 1;
    } while (currentPageResult.length >= assetFetchPageSize);
    return result;
  }

// _getLocalAssetsDiff compares local db with the file system and compute
// the files which needs to be added or removed from device collection.
  static FullDiffWithOnDevice _computeFullDiffWithOnDevice(
    FullDiffReqParams diffParams,
  ) {
    final Set<String> inAppAssetIDs = diffParams.inAppAssetIDs;
    final Map<String, Set<String>> inAppPathToLocalIDs =
        diffParams.inAppPathToLocalIDs;
    // Step 1: Build onDevicePathToLocalIDs and missingAssetsInApp
    final Set<String> onDeviceAssetIDs = {};
    final Map<String, Set<String>> onDevicePathToLocalIDs = {};
    final Map<String, AssetEntity> uniqueMissingAssetsInApp = {};

    for (var diff in diffParams.allOnDeviceAssets) {
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

    // Step 4: Add path are on device but not in app
    for (var pathID in onDevicePathToLocalIDs.keys) {
      if (!inAppPathToLocalIDs.containsKey(pathID) &&
          onDevicePathToLocalIDs[pathID]!.isNotEmpty) {
        updatePathToLocalIDs[pathID] = onDevicePathToLocalIDs[pathID]!;
      }
    }

    return FullDiffWithOnDevice(
      missingAssetsInApp: uniqueMissingAssetsInApp.values.toList(),
      extraAssetIDsInApp: extraAssetIDsInApp,
      extraPathIDsInApp: extraPathIDsInApp,
      updatePathToLocalIDs: updatePathToLocalIDs,
    );
  }

// review: do we need to run this inside compute, after making File.FromAsset
// sync. If yes, update the method documentation with reason.
  Future<IncrementalDiffWithOnDevice> _computeIncrementalDiffWithOnDevice(
    IncrementalDiffReqParams req,
  ) async {
    final List<AssetPathEntity> addedOrModifiedPaths = [];
    final List<AssetEntity> addedOrModifiedAssets = [];
    final Set<String> processedAssetIds = {};
    final Set<String> updatedInAppAssetIds = {};
    final Map<String, Set<String>> newOrUpdatedPathToLocalIDs = {};
    final int fromInSec = req.fromTimeInMs ~/ 1000;
    for (final DevicePathAssets pathAssets in req.newOrUpdatedLocalPaths) {
      addedOrModifiedPaths.add(pathAssets.path);
      final String pathID = pathAssets.path.id;
      final Set<String> localIDs = {};
      for (final AssetEntity asset in pathAssets.assets) {
        final String assetID = asset.id;
        localIDs.add(assetID);
        if (processedAssetIds.contains(assetID) ||
            max(asset.createDateSecond ?? 0, asset.modifiedDateSecond ?? 0) <
                fromInSec) {
          continue;
        }

        processedAssetIds.add(assetID);
        addedOrModifiedAssets.add(asset);
        if (req.inAppAssetIDs.contains(assetID)) {
          updatedInAppAssetIds.add(assetID);
        }
      }

      newOrUpdatedPathToLocalIDs[pathID] = localIDs;
    }
    return IncrementalDiffWithOnDevice(
      addedOrModifiedPaths,
      newOrUpdatedPathToLocalIDs,
      addedOrModifiedAssets,
      updatedInAppAssetIds,
    );
  }
}
