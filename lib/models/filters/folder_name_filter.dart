import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/photo.dart';
import 'package:path/path.dart' as path;

class FolderNameFilter implements GalleryItemsFilter {
  final String folderName;

  FolderNameFilter(this.folderName);

  @override
  bool shouldInclude(Photo photo) {
    return path.basename(photo.pathName) == folderName;
  }
}
