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

class DevicePathCollection {
  final String id;
  final String name;
  final String path;
  final String coverId;
  final int count;
  final bool sync;
  final int collectionID;
  File thumbnail;

  DevicePathCollection(
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
