import 'package:photos/models/file.dart';

class DeviceFolder {
  final String name;
  final String path;
  final File thumbnail;

  DeviceFolder(
    this.name,
    this.path,
    this.thumbnail,
  );
}

class DeviceCollection {
  final String id;
  final String name;
  final String path;
  final String coverId;
  final int count;
  final bool sync;
  int collectionID;
  File thumbnail;

  DeviceCollection(
    this.id,
    this.name, {
    this.path,
    this.coverId,
    this.count,
    this.collectionID,
    this.thumbnail,
    this.sync = false,
  });
}
