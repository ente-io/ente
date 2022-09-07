import 'package:photos/models/file.dart';
import 'package:photos/models/upload_strategy.dart';

class DeviceCollection {
  final String id;
  final String name;
  final String coverId;
  final int count;
  final bool shouldBackup;
  final UploadStrategy uploadStrategy;
  int collectionID;
  File thumbnail;

  DeviceCollection(
    this.id,
    this.name, {
    this.coverId,
    this.count,
    this.collectionID,
    this.thumbnail,
    this.shouldBackup = false,
    this.uploadStrategy = UploadStrategy.ifMissing,
  });
}
