// @dart = 2.9
import 'package:photos/models/file.dart';
import 'package:photos/models/upload_strategy.dart';

class DeviceCollection {
  final String id;
  final String name;
  final String coverId;
  final int count;
  final bool shouldBackup;
  UploadStrategy uploadStrategy;

  int collectionID;
  File thumbnail;

  DeviceCollection(
    this.id,
    this.name, {
    this.coverId,
    this.count,
    this.collectionID,
    this.thumbnail,
    this.uploadStrategy = UploadStrategy.ifMissing,
    this.shouldBackup = false,
  });
}
