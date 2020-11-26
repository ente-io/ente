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
