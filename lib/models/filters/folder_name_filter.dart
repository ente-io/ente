import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart' as path;

class FolderNameFilter implements GalleryItemsFilter {
  final String folderName;

  FolderNameFilter(this.folderName);

  @override
  bool shouldInclude(File file) {
    return path.basename(file.deviceFolder) == folderName;
  }
}
