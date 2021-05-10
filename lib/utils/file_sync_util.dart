import 'dart:math';

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
        final file = await File.fromAsset(pathEntity, entity);
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
