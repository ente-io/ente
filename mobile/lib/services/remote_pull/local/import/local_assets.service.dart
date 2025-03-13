import 'dart:io';
import 'dart:math';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_import_progress.dart';
import "package:photos/services/remote_pull/local/import/model.dart";

class LocalAssetsService {
  final _logger = Logger("LocalAssetsService");
  static const ignoreSizeConstraint = SizeConstraint(ignoreSize: true);
  static const assetFetchPageSize = 2000;
  Future<List<LocalPathAssets>> getAssetPathAndEntities(
    int fromTimeInMicroSec,
    int toTimeInMicroSec,
  ) async {
    final pathEntities = await _getGalleryList(
      updateFromTimeInMicroSec: fromTimeInMicroSec,
      updateToTimeInMicroSec: toTimeInMicroSec,
    );
    final List<LocalPathAssets> localPathAssets = [];
    for (AssetPathEntity pathEntity in pathEntities) {
      final List<AssetEntity> assetsInPath =
          await _getAllAssetLists(pathEntity);
      try {
        final List<AssetEntity> result = assetsInPath.isEmpty
            ? []
            : await Computer.shared().compute(
                _getLocalIDsAndFilesFromAssets,
                param: <String, dynamic>{
                  "assetList": assetsInPath,
                  "fromTimeInMicroSec": fromTimeInMicroSec,
                },
                taskName:
                    "getLocalPathAssetsAndFiles-${pathEntity.name}-count-${assetsInPath.length}",
              );
        localPathAssets.add(
          LocalPathAssets(path: pathEntity, assets: result),
        );
      } catch (e) {
        _logger.severe("_getLocalIDsAndFilesFromAssets failed", e);
        _logger.info(
          "Failed for pathEntity: ${pathEntity.name}",
        );
        rethrow;
      }
    }
    return localPathAssets;
  }

  Future<List<LocalPathAssets>> getAllLocalAssets() async {
    final List<AssetPathEntity> assetPaths = await _getGalleryList();
    final List<LocalPathAssets> localPathAssets = [];
    for (final assetPath in assetPaths) {
      final List<AssetEntity> assets = await _getAllAssetLists(assetPath);
      localPathAssets.add(
        LocalPathAssets(
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
  Future<List<AssetPathEntity>> _getGalleryList({
    final int? updateFromTimeInMicroSec,
    final int? updateToTimeInMicroSec,
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
    if (updateFromTimeInMicroSec != null && updateToTimeInMicroSec != null) {
      filterOptionGroup.updateTimeCond = DateTimeCond(
        min: DateTime.fromMillisecondsSinceEpoch(
          updateFromTimeInMicroSec ~/ 1000,
        ),
        max:
            DateTime.fromMillisecondsSinceEpoch(updateToTimeInMicroSec ~/ 1000),
      );
    } else {
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

  Future<List<AssetEntity>> _getAllAssetLists(
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

  Future<LocalDiffResult> getDiffFromExistingImport(
    List<LocalPathAssets> allOnDeviceAssets,
    // current set of assets available on device
    Set<String> inAppAssetIDs, // localIDs of files already imported in app
    Map<String, Set<String>> inAppPathToLocalIDs,
  ) async {
    final LocalDiffResult diffResult =
        await Computer.shared().compute<_DiffParams, LocalDiffResult>(
      _getLocalAssetsDiff,
      param: _DiffParams(allOnDeviceAssets, inAppAssetIDs, inAppPathToLocalIDs),
      taskName: "getLocalAssetsDiff",
    );
    return diffResult;
  }

// _getLocalAssetsDiff compares local db with the file system and compute
// the files which needs to be added or removed from device collection.
  LocalDiffResult _getLocalAssetsDiff(_DiffParams diffParams) {
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

    return LocalDiffResult(
      missingAssetsInApp: uniqueMissingAssetsInApp.values.toList(),
      extraAssetIDsInApp: extraAssetIDsInApp,
      extraPathIDsInApp: extraPathIDsInApp,
      updatePathToLocalIDs: updatePathToLocalIDs,
    );
  }

// review: do we need to run this inside compute, after making File.FromAsset
// sync. If yes, update the method documentation with reason.
  Future<List<AssetEntity>> _getLocalIDsAndFilesFromAssets(
    Map<String, dynamic> args,
  ) async {
    final assetList = args["assetList"];
    final fromTime = args["fromTimeInMicroSec"];
    final List<AssetEntity> filteredAssets = [];
    for (AssetEntity entity in assetList) {
      final bool assetCreatedOrUpdatedAfterGivenTime = max(
            entity.createDateTime.millisecondsSinceEpoch,
            entity.modifiedDateTime.millisecondsSinceEpoch,
          ) >=
          (fromTime / ~1000);
      if (assetCreatedOrUpdatedAfterGivenTime) {
        filteredAssets.add(entity);
      }
    }
    return filteredAssets;
  }
}

class _DiffParams {
  final List<LocalPathAssets> allOnDeviceAssets;
  final Set<String> inAppAssetIDs;
  final Map<String, Set<String>> inAppPathToLocalIDs;

  _DiffParams(
    this.allOnDeviceAssets,
    this.inAppAssetIDs,
    this.inAppPathToLocalIDs,
  );
}
