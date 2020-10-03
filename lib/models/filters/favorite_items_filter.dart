import 'package:photos/services/favorites_service.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';

class FavoriteItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(File file) {
    return FavoritesService.instance.isLiked(file);
  }
}
