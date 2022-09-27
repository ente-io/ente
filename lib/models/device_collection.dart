import 'package:photos/models/file.dart';
import 'package:photos/models/upload_strategy.dart';

class DeviceCollection {
  final String id;
  final String name;
  final int count;
  final bool shouldBackup;
  UploadStrategy uploadStrategy;
  final String? coverId;
  int? collectionID;
  File? thumbnail;

  DeviceCollection(
    this.id,
    this.name, {
    this.coverId,
    this.count = 0,
    this.collectionID,
    this.thumbnail,
    this.uploadStrategy = UploadStrategy.ifMissing,
    this.shouldBackup = false,
  });
}
