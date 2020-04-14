import 'package:myapp/models/photo.dart';
import 'package:myapp/utils/gallery_items_filter.dart';

class CameraItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(Photo photo) {
    // TODO: Improve logic
    return photo.localPath.contains("Camera");
  }
}
