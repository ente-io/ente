import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';

class DeviceFolder {
  final String name;
  final String path;
  final List<File> Function() loader;
  final File thumbnail;
  final GalleryItemsFilter filter;

  DeviceFolder(
    this.name,
    this.path,
    this.loader,
    this.thumbnail, {
    this.filter,
  });
}
