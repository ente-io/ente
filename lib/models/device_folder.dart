import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';

class DeviceFolder {
  final String name;
  final String path;
  final File thumbnail;
  final GalleryItemsFilter filter;

  DeviceFolder(
    this.name,
    this.path,
    this.thumbnail, {
    this.filter,
  });
}
