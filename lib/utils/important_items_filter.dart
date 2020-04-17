import 'package:myapp/models/photo.dart';
import 'package:myapp/utils/gallery_items_filter.dart';

class ImportantItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(Photo photo) {
    // TODO: Improve logic
    return photo.localPath.contains("/Camera/") ||
        photo.localPath.contains("/Download/") ||
        photo.localPath.contains("/Screenshots/");
  }
}
