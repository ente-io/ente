import 'dart:math';

import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';

Future<List<File>> getDeviceFiles(Map<String, dynamic> params) async {
  final lastDBUpdationTime = params["lastDBUpdationTime"];
  final syncStartTime = params["syncStartTime"];
  final pathEntities = await _getGalleryList(lastDBUpdationTime, syncStartTime);
  final files = List<File>();
  AssetPathEntity recents;
  for (AssetPathEntity pathEntity in pathEntities) {
    if (pathEntity.name == "Recent" || pathEntity.name == "Recents") {
      recents = pathEntity;
    } else {
      await _addToPhotos(pathEntity, lastDBUpdationTime, files);
    }
  }
  if (recents != null) {
    await _addToPhotos(recents, lastDBUpdationTime, files);
  }
  files.sort(
      (first, second) => first.creationTime.compareTo(second.creationTime));
  return files;
}

Future<List<AssetPathEntity>> _getGalleryList(
    final int fromTimestamp, final int toTimestamp) async {
  final filterOptionGroup = FilterOptionGroup();
  filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
  filterOptionGroup.setOption(AssetType.video, FilterOption(needTitle: true));
  filterOptionGroup.dateTimeCond = DateTimeCond(
    min: DateTime.fromMicrosecondsSinceEpoch(fromTimestamp),
    max: DateTime.fromMicrosecondsSinceEpoch(toTimestamp),
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

Future _addToPhotos(AssetPathEntity pathEntity, int lastDBUpdationTime,
    List<File> files) async {
  final assetList = await pathEntity.assetList;
  for (AssetEntity entity in assetList) {
    if (max(entity.createDateTime.microsecondsSinceEpoch,
            entity.modifiedDateTime.microsecondsSinceEpoch) >
        lastDBUpdationTime) {
      try {
        final file = await File.fromAsset(pathEntity, entity);
        if (!files.contains(file)) {
          files.add(file);
        }
      } catch (e) {
        // _logger.severe(e);
      }
    }
  }
}
