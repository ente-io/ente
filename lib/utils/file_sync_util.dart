import 'dart:math';

import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';

Future<List<File>> getDeviceFiles(int fromTime, int toTime) async {
  final pathEntities = await _getGalleryList(fromTime, toTime);
  final files = List<File>();
  AssetPathEntity recents;
  for (AssetPathEntity pathEntity in pathEntities) {
    if (pathEntity.name == "Recent" || pathEntity.name == "Recents") {
      recents = pathEntity;
    } else {
      await _addToPhotos(pathEntity, fromTime, files);
    }
  }
  if (recents != null) {
    await _addToPhotos(recents, fromTime, files);
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

Future _addToPhotos(
    AssetPathEntity pathEntity, int fromTime, List<File> files) async {
  final assetList = await pathEntity.assetList;
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
        Logger("FileSyncUtil").severe(e);
      }
    }
  }
}
