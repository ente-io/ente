import 'dart:io';
import 'dart:math';

import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_import_progress.dart';
import "package:photos/services/remote_pull/local/import/model.dart";

final _logger = Logger("FileSyncUtil");
const ignoreSizeConstraint = SizeConstraint(ignoreSize: true);
const assetFetchPageSize = 2000;

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
    final List<AssetEntity> assetsInPath = await _getAllAssetLists(pathEntity);
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
      min:
          DateTime.fromMillisecondsSinceEpoch(updateFromTimeInMicroSec ~/ 1000),
      max: DateTime.fromMillisecondsSinceEpoch(updateToTimeInMicroSec ~/ 1000),
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
