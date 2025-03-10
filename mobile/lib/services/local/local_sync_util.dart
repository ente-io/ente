import 'dart:io';
import 'dart:math';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_import_progress.dart';
import 'package:photos/models/file/file.dart';
import 'package:tuple/tuple.dart';

final _logger = Logger("FileSyncUtil");
const ignoreSizeConstraint = SizeConstraint(ignoreSize: true);
const assetFetchPageSize = 2000;

Future<Tuple2<List<LocalPathAsset>, List<EnteFile>>> getLocalPathAssetsAndFiles(
  int fromTime,
  int toTime,
) async {
  final pathEntities = await _getGalleryList(
    updateFromTime: fromTime,
    updateToTime: toTime,
  );
  final List<LocalPathAsset> localPathAssets = [];

  // alreadySeenLocalIDs is used to track and ignore file with particular
  // localID if it's already present in another album. This only impacts iOS
  // devices where a file can belong to multiple
  final Set<String> alreadySeenLocalIDs = {};
  final List<EnteFile> uniqueFiles = [];
  for (AssetPathEntity pathEntity in pathEntities) {
    final List<AssetEntity> assetsInPath = await _getAllAssetLists(pathEntity);
    late Tuple2<Set<String>, List<EnteFile>> result;
    if (assetsInPath.isEmpty) {
      result = const Tuple2({}, []);
    } else {
      try {
        result = await Computer.shared().compute(
          _getLocalIDsAndFilesFromAssets,
          param: <String, dynamic>{
            "pathEntity": pathEntity,
            "fromTime": fromTime,
            "alreadySeenLocalIDs": alreadySeenLocalIDs,
            "assetList": assetsInPath,
          },
          taskName:
              "getLocalPathAssetsAndFiles-${pathEntity.name}-count-${assetsInPath.length}",
        );
      } catch (e) {
        _logger.severe("_getLocalIDsAndFilesFromAssets failed", e);
        _logger.info(
          "Failed for pathEntity: ${pathEntity.name}",
        );
        rethrow;
      }

      alreadySeenLocalIDs.addAll(result.item1);
      uniqueFiles.addAll(result.item2);
    }
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
  final List<Tuple2<AssetPathEntity, String>> result = [];
  final pathEntities = await _getGalleryList(
    needsTitle: false,
    containsModifiedPath: true,
    orderOption:
        const OrderOption(type: OrderOptionType.createDate, asc: false),
  );
  for (AssetPathEntity pathEntity in pathEntities) {
    final latestEntity = await pathEntity.getAssetListPaged(
      page: 0,
      size: 1,
    );
    final String localCoverID =
        latestEntity.isEmpty ? '' : latestEntity.first.id;
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
    hasAll: !Platform.isAndroid,
    type: RequestType.common,
    filterOption: filterOptionGroup,
  );
  final List<LocalPathAsset> localPathAssets = [];
  for (final assetPath in assetPaths) {
    final Set<String> localIDs = <String>{};
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

Future<LocalDiffResult> getDiffWithLocal(
  List<LocalPathAsset> assets,
  // current set of assets available on device
  Set<String> existingIDs, // localIDs of files already imported in app
  Map<String, Set<String>> pathToLocalIDs,
) async {
  final Map<String, dynamic> args = <String, dynamic>{};
  args['assets'] = assets;
  args['existingIDs'] = existingIDs;
  args['pathToLocalIDs'] = pathToLocalIDs;
  final LocalDiffResult diffResult = await Computer.shared().compute(
    _getLocalAssetsDiff,
    param: args,
    taskName: "getLocalAssetsDiff",
  );
  if (diffResult.localPathAssets != null) {
    diffResult.uniqueLocalFiles =
        await _convertLocalAssetsToUniqueFiles(diffResult.localPathAssets!);
  }
  return diffResult;
}

// _getLocalAssetsDiff compares local db with the file system and compute
// the files which needs to be added or removed from device collection.
LocalDiffResult _getLocalAssetsDiff(Map<String, dynamic> args) {
  final List<LocalPathAsset> onDeviceLocalPathAsset = args['assets'];
  final Set<String> existingIDs = args['existingIDs'];
  final Map<String, Set<String>> pathToLocalIDs = args['pathToLocalIDs'];
  final Map<String, Set<String>> newPathToLocalIDs = <String, Set<String>>{};
  final Map<String, Set<String>> removedPathToLocalIDs =
      <String, Set<String>>{};
  final List<LocalPathAsset> unsyncedAssets = [];

  for (final localPathAsset in onDeviceLocalPathAsset) {
    final String pathID = localPathAsset.pathID;
    // Start identifying pathID to localID mapping changes which needs to be
    // synced
    final Set<String> candidateLocalIDsForRemoval =
        pathToLocalIDs[pathID] ?? <String>{};
    final Set<String> missingLocalIDsInPath = <String>{};
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
    if (localPathAsset.localIDs.isNotEmpty) {
      unsyncedAssets.add(localPathAsset);
    }
  }
  return LocalDiffResult(
    localPathAssets: unsyncedAssets,
    newPathToLocalIDs: newPathToLocalIDs,
    deletePathToLocalIDs: removedPathToLocalIDs,
  );
}

Future<List<EnteFile>> _convertLocalAssetsToUniqueFiles(
  List<LocalPathAsset> assets,
) async {
  final Set<String> alreadySeenLocalIDs = <String>{};
  final List<EnteFile> files = [];
  for (LocalPathAsset localPathAsset in assets) {
    final String localPathName = localPathAsset.pathName;
    for (final String localID in localPathAsset.localIDs) {
      if (!alreadySeenLocalIDs.contains(localID)) {
        final assetEntity = await AssetEntity.fromId(localID);
        if (assetEntity == null) {
          _logger.warning('Failed to fetch asset with id $localID');
          continue;
        }
        files.add(
          await EnteFile.fromAsset(localPathName, assetEntity),
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
  final int? updateFromTime,
  final int? updateToTime,
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

  if (updateFromTime != null && updateToTime != null) {
    filterOptionGroup.updateTimeCond = DateTimeCond(
      min: DateTime.fromMillisecondsSinceEpoch(updateFromTime ~/ 1000),
      max: DateTime.fromMillisecondsSinceEpoch(updateToTime ~/ 1000),
    );
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

Future<List<AssetEntity>> _getAllAssetLists(AssetPathEntity pathEntity) async {
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

// review: do we need to run this inside compute, after making File.FromAsset
// sync. If yes, update the method documentation with reason.
Future<Tuple2<Set<String>, List<EnteFile>>> _getLocalIDsAndFilesFromAssets(
  Map<String, dynamic> args,
) async {
  final pathEntity = args["pathEntity"] as AssetPathEntity;
  final assetList = args["assetList"];
  final fromTime = args["fromTime"];
  final alreadySeenLocalIDs = args["alreadySeenLocalIDs"] as Set<String>;
  final List<EnteFile> files = [];
  final Set<String> localIDs = {};
  for (AssetEntity entity in assetList) {
    localIDs.add(entity.id);
    final bool assetCreatedOrUpdatedAfterGivenTime = max(
          entity.createDateTime.millisecondsSinceEpoch,
          entity.modifiedDateTime.millisecondsSinceEpoch,
        ) >=
        (fromTime / ~1000);
    if (!alreadySeenLocalIDs.contains(entity.id) &&
        assetCreatedOrUpdatedAfterGivenTime) {
      final file = await EnteFile.fromAsset(pathEntity.name, entity);
      files.add(file);
    }
  }
  return Tuple2(localIDs, files);
}

class LocalPathAsset {
  final Set<String> localIDs;
  final String pathID;
  final String pathName;

  LocalPathAsset({
    required this.localIDs,
    required this.pathName,
    required this.pathID,
  });
}

class LocalDiffResult {
  // unique localPath Assets.
  final List<LocalPathAsset>? localPathAssets;

  // set of File object created from localPathAssets
  List<EnteFile>? uniqueLocalFiles;

  // newPathToLocalIDs represents new entries which needs to be synced to
  // the local db
  final Map<String, Set<String>>? newPathToLocalIDs;

  final Map<String, Set<String>>? deletePathToLocalIDs;

  LocalDiffResult({
    this.uniqueLocalFiles,
    this.localPathAssets,
    this.newPathToLocalIDs,
    this.deletePathToLocalIDs,
  });
}
