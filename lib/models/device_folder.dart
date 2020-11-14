import 'package:photos/models/file.dart';

class DeviceFolder {
  final String name;
  final String path;
  final File thumbnail;
  final List<File> files;

  DeviceFolder(
    this.name,
    this.path,
    this.thumbnail,
    this.files,
  );
}
