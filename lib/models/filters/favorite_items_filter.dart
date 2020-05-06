import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/photo.dart';

class FavoriteItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(Photo photo) {
    return FavoritePhotosRepository.instance.isLiked(photo);
  }
}
