import 'dart:math';

import 'package:computer/computer.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';
import 'package:tuple/tuple.dart';

final _logger = Logger("FileSyncUtil");
const ignoreSizeConstraint = SizeConstraint(ignoreSize: true);
const assetFetchPageSize = 2000;

Future<Tuple2<List<LocalPathAsset>, List<File>>> getLocalPathAssetsAndFiles(
  int fromTime,
  int toTime,
  Computer computer,
) async {
  final pathEntities = await _getGalleryList(
    updateFromTime: fromTime,
    updateToTime: toTime,
  );
  List<LocalPathAsset> localPathAssets = [];

  // alreadySeenLocalIDs is used to track and ignore file with particular
  // localID if it's already present in another album. This only impacts iOS
  // devices where a file can belong to multiple
  Set<String> alreadySeenLocalIDs = {};
  List<File> uniqueFiles = [];
  for (AssetPathEntity pathEntity in pathEntities) {
    List<AssetEntity> assetsInPath = await _getAllAssetLists(pathEntity);
    Tuple2<Set<String>, List<File>> result = await computer.compute(
      _getLocalIDsAndFilesFromAssets,
      param: <String, dynamic>{
        "pathEntity": pathEntity,
        "fromTime": fromTime,
        "alreadySeenLocalIDs": alreadySeenLocalIDs,
        "assetList": assetsInPath,
      },
    );
    alreadySeenLocalIDs.addAll(result.item1);
    uniqueFiles.addAll(result.item2);
    localPathAssets.add(
      LocalPathAsset(
        localIDs: result.item1,
        pathName: pathEntity.name,
        pathID: pathEntity.id,
      ),
    );
  }
  return Tuple2(localPathAssets, uniqueFiles);
}

// getDeviceFolderWithCountAndLatestFile returns a tuple of AssetPathEntity and
// latest file's localID in the assetPath, along with modifiedPath time and
// total count of assets in a Asset Path.
// We use this result to update the latest thumbnail for deviceFolder and
// identify (in future) which AssetPath needs to be re-synced again.
Future<List<Tuple2<AssetPathEntity, String>>>
    getDeviceFolderWithCountAndCoverID() async {
  List<Tuple2<AssetPathEntity, String>> result = [];
  final pathEntities = await _getGalleryList(
    needsTitle: false,
    containsModifiedPath: true,
    orderOption:
        const OrderOption(type: OrderOptionType.createDate, asc: false),
  );
  for (AssetPathEntity pathEntity in pathEntities) {
    //todo: test and handle empty album case
    var latestEntity = await pathEntity.getAssetListPaged(
      page: 0,
      size: 1,
    );
    String localCoverID = latestEntity.first.id;
    result.add(Tuple2(pathEntity, localCoverID));
  }
  return result;
}

Future<List<LocalPathAsset>> getAllLocalAssets() async {
  final filterOptionGroup = FilterOptionGroup();
  filterOptionGroup.setOption(
    AssetType.image,
    const FilterOption(sizeConstraint: ignoreSizeConstraint),
  );
  filterOptionGroup.setOption(
    AssetType.video,
    const FilterOption(sizeConstraint: ignoreSizeConstraint),
  );
  filterOptionGroup.createTimeCond = DateTimeCond.def().copyWith(ignore: true);
  final assetPaths = await PhotoManager.getAssetPathList(
    hasAll: true,
    type: RequestType.common,
    filterOption: filterOptionGroup,
  );
  final List<LocalPathAsset> localPathAssets = [];
  for (final assetPath in assetPaths) {
    Set<String> localIDs = <String>{};
    for (final asset in await _getAllAssetLists(assetPath)) {
      localIDs.add(asset.id);
    }
    localPathAssets.add(
      LocalPathAsset(
        localIDs: localIDs,
        pathName: assetPath.name,
        pathID: assetPath.id,
      ),
    );
  }
  return localPathAssets;
}

Future<LocalUnSyncResult> getLocalUnSyncedFiles(
  List<LocalPathAsset> assets,
  // current set of assets available on device
  Set<String> existingIDs, // localIDs of files already imported in app
  Map<String, Set<String>> pathToLocalIDs,
  Set<String> invalidIDs,
  Computer computer,
) async {
  final Map<String, dynamic> args = <String, dynamic>{};
  args['assets'] = assets;
  args['existingIDs'] = existingIDs;
  args['invalidIDs'] = invalidIDs;
  args['pathToLocalIDs'] = pathToLocalIDs;
  final LocalUnSyncResult localUnSyncResult =
      await computer.compute(_getUnsyncedAssets, param: args);
  if (localUnSyncResult.localPathAssets.isEmpty) {
    return localUnSyncResult;
  }
  final unSyncedFiles =
      await _convertLocalAssetsToUniqueFiles(localUnSyncResult.localPathAssets);
  localUnSyncResult.uniqueLocalFiles = unSyncedFiles;
  return localUnSyncResult;
}

// _getUnsyncedAssets performs following operation
// Identify
LocalUnSyncResult _getUnsyncedAssets(Map<String, dynamic> args) {
  final List<LocalPathAsset> onDeviceLocalPathAsset = args['assets'];
  final Set<String> existingIDs = args['existingIDs'];
  final Set<String> invalidIDs = args['invalidIDs'];
  final Map<String, Set<String>> pathToLocalIDs = args['pathToLocalIDs'];
  final Map<String, Set<String>> newPathToLocalIDs = <String, Set<String>>{};
  final Map<String, Set<String>> removedPathToLocalIDs =
      <String, Set<String>>{};
  final List<LocalPathAsset> unsyncedAssets = [];

  for (final localPathAsset in onDeviceLocalPathAsset) {
    String pathID = localPathAsset.pathID;
    // Start identifying pathID to localID mapping changes which needs to be
    // synced
    Set<String> candidateLocalIDsForRemoval =
        pathToLocalIDs[pathID] ?? <String>{};
    Set<String> missingLocalIDsInPath = <String>{};
    for (final String localID in localPathAsset.localIDs) {
      if (candidateLocalIDsForRemoval.contains(localID)) {
        // remove the localID after checking. Any pending existing ID indicates
        // the the local file was removed from the path.
        candidateLocalIDsForRemoval.remove(localID);
      } else {
        missingLocalIDsInPath.add(localID);
      }
    }
    if (candidateLocalIDsForRemoval.isNotEmpty) {
      removedPathToLocalIDs[pathID] = candidateLocalIDsForRemoval;
    }
    if (missingLocalIDsInPath.isNotEmpty) {
      newPathToLocalIDs[pathID] = missingLocalIDsInPath;
    }
    // End

    localPathAsset.localIDs.removeAll(existingIDs);
    localPathAsset.localIDs.removeAll(invalidIDs);
    if (localPathAsset.localIDs.isNotEmpty) {
      unsyncedAssets.add(localPathAsset);
    }
  }
  return LocalUnSyncResult(
    localPathAssets: unsyncedAssets,
    newPathToLocalIDs: newPathToLocalIDs,
    deletePathToLocalIDs: removedPathToLocalIDs,
  );
}

Future<List<File>> _convertLocalAssetsToUniqueFiles(
  List<LocalPathAsset> assets,
) async {
  final Set<String> alreadySeenLocalIDs = <String>{};
  final List<File> files = [];
  for (LocalPathAsset localPathAsset in assets) {
    String localPathName = localPathAsset.pathName;
    for (final String localID in localPathAsset.localIDs) {
      if (!alreadySeenLocalIDs.contains(localID)) {
        var assetEntity = await AssetEntity.fromId(localID);
        files.add(
          File.fromAsset(localPathName, assetEntity),
        );
        alreadySeenLocalIDs.add(localID);
      }
    }
  }
  return files;
}

/// returns a list of AssetPathEntity with relevant filter operations.
/// [needTitle] impacts the performance for fetching the actual [AssetEntity]
/// in iOS. Same is true for [containsModifiedPath]
Future<List<AssetPathEntity>> _getGalleryList({
  final int updateFromTime,
  final int updateToTime,
  final bool containsModifiedPath = false,
  // in iOS fetching the AssetEntity title impacts performance
  final bool needsTitle = true,
  final OrderOption orderOption,
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

  if (updateFromTime != null && updateToTime != null) {
    filterOptionGroup.updateTimeCond = DateTimeCond(
      min: DateTime.fromMicrosecondsSinceEpoch(updateFromTime),
      max: DateTime.fromMicrosecondsSinceEpoch(updateToTime),
    );
  }
  filterOptionGroup.containsPathModified = containsModifiedPath;
  final galleryList = await PhotoManager.getAssetPathList(
    hasAll: true,
    type: RequestType.common,
    filterOption: filterOptionGroup,
  );

  // todo: assetCount will be deprecated in the new version.
  // disable sorting and either try to evaluate if it's required or yolo
  galleryList.sort((s1, s2) {
    return s2.assetCount.compareTo(s1.assetCount);
  });
  return galleryList;
}

Future<List<AssetEntity>> _getAllAssetLists(AssetPathEntity pathEntity) async {
  List<AssetEntity> result = [];
  int currentPage = 0;
  List<AssetEntity> currentPageResult = [];
  do {
    currentPageResult = await pathEntity.getAssetListPaged(
      page: currentPage,
      size: assetFetchPageSize,
    );
    result.addAll(currentPageResult);
    currentPage = currentPage + 1;
  } while (currentPageResult.length >= assetFetchPageSize);
  return result;
}

// review: do we need to run this inside compute, after making File.FromAsset
// sync. If yes, update the method documentation with reason.
Future<Tuple2<Set<String>, List<File>>> _getLocalIDsAndFilesFromAssets(
  Map<String, dynamic> args,
) async {
  final pathEntity = args["pathEntity"] as AssetPathEntity;
  final assetList = args["assetList"];
  final fromTime = args["fromTime"];
  final alreadySeenLocalIDs = args["alreadySeenLocalIDs"] as Set<String>;
  final List<File> files = [];
  final Set<String> localIDs = {};
  for (AssetEntity entity in assetList) {
    localIDs.add(entity.id);
    bool assetCreatedOrUpdatedAfterGivenTime = max(
          entity.createDateTime.microsecondsSinceEpoch,
          entity.modifiedDateTime.microsecondsSinceEpoch,
        ) >
        fromTime;
    if (!alreadySeenLocalIDs.contains(entity.id) &&
        assetCreatedOrUpdatedAfterGivenTime) {
      try {
        final file = File.fromAsset(pathEntity.name, entity);
        files.add(file);
      } catch (e) {
        _logger.severe(e);
      }
    }
  }
  return Tuple2(localIDs, files);
}

class LocalPathAsset {
  final Set<String> localIDs;
  final String pathID;
  final String pathName;

  LocalPathAsset({
    @required this.localIDs,
    @required this.pathName,
    @required this.pathID,
  });
}

class LocalUnSyncResult {
  // unique localPath Assets.
  final List<LocalPathAsset> localPathAssets;

  // set of File object created from localPathAssets
  List<File> uniqueLocalFiles;

  // newPathToLocalIDs represents new entries which needs to be synced to
  // the local db
  final Map<String, Set<String>> newPathToLocalIDs;

  final Map<String, Set<String>> deletePathToLocalIDs;

  LocalUnSyncResult({
    this.uniqueLocalFiles,
    this.localPathAssets,
    this.newPathToLocalIDs,
    this.deletePathToLocalIDs,
  });
}
