import "package:photo_manager/photo_manager.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/upload_strategy.dart';

class DeviceCollection {
  AssetPathEntity assetPathEntity;
  final int count;
  final bool shouldBackup;
  UploadStrategy uploadStrategy;
  int? collectionID;
  EnteFile? thumbnail;

  bool hasCollectionID() {
    return collectionID != null && collectionID! != -1;
  }

  String get name {
    return assetPathEntity.name;
  }

  String get id {
    return assetPathEntity.id;
  }

  DeviceCollection(
    this.assetPathEntity, {
    this.count = 0,
    this.collectionID,
    this.thumbnail,
    this.uploadStrategy = UploadStrategy.ifMissing,
    this.shouldBackup = false,
  });
}
