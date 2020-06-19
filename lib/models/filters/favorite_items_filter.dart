import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';

class FavoriteItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(File file) {
    return FavoriteFilesRepository.instance.isLiked(file);
  }
}
