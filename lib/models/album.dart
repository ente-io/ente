import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/photo.dart';

class Album {
  final String name;
  final Photo thumbnailPhoto;
  final GalleryItemsFilter filter;

  Album(this.name, this.thumbnailPhoto, this.filter);
}
