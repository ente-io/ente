import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:computer/computer.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';

final _logger = Logger("FileSyncUtil");

Future<List<File>> getDeviceFiles(
    int fromTime, int toTime, Computer computer) async {
  final pathEntities = await _getGalleryList(fromTime, toTime);
  List<File> files = [];
  AssetPathEntity recents;
  for (AssetPathEntity pathEntity in pathEntities) {
    if (pathEntity.name == "Recent" || pathEntity.name == "Recents") {
      recents = pathEntity;
    } else {
      files = await _computeFiles(pathEntity, fromTime, files, computer);
    }
  }
  if (recents != null) {
    files = await _computeFiles(recents, fromTime, files, computer);
  }
  files.sort(
      (first, second) => first.creationTime.compareTo(second.creationTime));
  return files;
}

Future<List<LocalAsset>> getAllLocalAssets() async {
  final filterOptionGroup = FilterOptionGroup();
  final assetPaths = await PhotoManager.getAssetPathList(
    hasAll: true,
    type: RequestType.common,
    filterOption: filterOptionGroup,
  );
  final List<LocalAsset> assets = [];
  for (final assetPath in assetPaths) {
    for (final asset in await assetPath.assetList) {
      assets.add(LocalAsset(asset.id, assetPath.name));
    }
  }
  return assets;
}

Future<List<File>> getUnsyncedFiles(List<LocalAsset> assets,
    Set<String> existingIDs, Set<String> invalidIDs, Computer computer) async {
  final args = Map<String, dynamic>();
  args['assets'] = assets;
  args['existingIDs'] = existingIDs;
  args['invalidIDs'] = invalidIDs;
  final unsyncedAssets =
      await computer.compute(_getUnsyncedAssets, param: args);
  if (unsyncedAssets.isEmpty) {
    return [];
  }
  return _convertToFiles(unsyncedAssets, computer);
}

List<LocalAsset> _getUnsyncedAssets(Map<String, dynamic> args) {
  final List<LocalAsset> assets = args['assets'];
  final Set<String> existingIDs = args['existingIDs'];
  final Set<String> invalidIDs = args['invalidIDs'];
  final List<LocalAsset> unsyncedAssets = [];
  for (final asset in assets) {
    if (!existingIDs.contains(asset.id) && !invalidIDs.contains(asset.id)) {
      unsyncedAssets.add(asset);
    }
  }
  return unsyncedAssets;
}

Future<List<File>> _convertToFiles(
    List<LocalAsset> assets, Computer computer) async {
  final List<LocalAsset> recents = [];
  final List<LocalAssetEntity> entities = [];
  for (final asset in assets) {
    if (asset.path == "Recent" || asset.path == "Recents") {
      recents.add(asset);
    } else {
      entities.add(
          LocalAssetEntity(await AssetEntity.fromId(asset.id), asset.path));
    }
  }
  // Ignore duplicate items in recents
  for (final recent in recents) {
    bool presentInOthers = false;
    for (final entity in entities) {
      if (recent.id == entity.entity.id) {
        presentInOthers = true;
        break;
      }
    }
    if (!presentInOthers) {
      entities.add(
          LocalAssetEntity(await AssetEntity.fromId(recent.id), recent.path));
    }
  }
  return await computer.compute(_getFilesFromAssets, param: entities);
}

Future<List<AssetPathEntity>> _getGalleryList(
    final int fromTime, final int toTime) async {
  final filterOptionGroup = FilterOptionGroup();
  filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
  filterOptionGroup.setOption(AssetType.video, FilterOption(needTitle: true));
  filterOptionGroup.createTimeCond = DateTimeCond(
    min: DateTime.fromMicrosecondsSinceEpoch(fromTime),
    max: DateTime.fromMicrosecondsSinceEpoch(toTime),
  );
  filterOptionGroup.updateTimeCond = DateTimeCond(
    min: DateTime.fromMicrosecondsSinceEpoch(fromTime),
    max: DateTime.fromMicrosecondsSinceEpoch(toTime),
  );
  final galleryList = await PhotoManager.getAssetPathList(
    hasAll: true,
    type: RequestType.common,
    filterOption: filterOptionGroup,
  );

  galleryList.sort((s1, s2) {
    return s2.assetCount.compareTo(s1.assetCount);
  });

  return galleryList;
}

Future<List<File>> _computeFiles(AssetPathEntity pathEntity, int fromTime,
    List<File> files, Computer computer) async {
  final args = Map<String, dynamic>();
  args["pathEntity"] = pathEntity;
  args["assetList"] = await pathEntity.assetList;
  args["fromTime"] = fromTime;
  args["files"] = files;
  return await computer.compute(_getFiles, param: args);
}

Future<List<File>> _getFiles(Map<String, dynamic> args) async {
  final pathEntity = args["pathEntity"];
  final assetList = args["assetList"];
  final fromTime = args["fromTime"];
  final files = args["files"];
  for (AssetEntity entity in assetList) {
    if (max(entity.createDateTime.microsecondsSinceEpoch,
            entity.modifiedDateTime.microsecondsSinceEpoch) >
        fromTime) {
      try {
        final file = await File.fromAsset(pathEntity.name, entity);
        if (!files.contains(file)) {
          files.add(file);
        }
      } catch (e) {
        _logger.severe(e);
      }
    }
  }
  return files;
}

Future<List<File>> _getFilesFromAssets(List<LocalAssetEntity> assets) async {
  final List<File> files = [];
  for (final asset in assets) {
    files.add(await File.fromAsset(
      asset.path,
      asset.entity,
    ));
  }
  return files;
}

class LocalAsset {
  final String id;
  final String path;

  LocalAsset(
    this.id,
    this.path,
  );
}

class LocalAssetEntity {
  final AssetEntity entity;
  final String path;

  LocalAssetEntity(this.entity, this.path);
}
