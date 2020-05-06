import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/photo.dart';

class Album {
  final String name;
  final List<Photo> photos;
  final GalleryItemsFilter filter;

  Album(this.name, this.photos, this.filter);
}
