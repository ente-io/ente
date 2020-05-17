import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/photo.dart';

class DeviceFolder {
  final String name;
  final Photo thumbnailPhoto;
  final GalleryItemsFilter filter;

  DeviceFolder(this.name, this.thumbnailPhoto, this.filter);
}
