import 'package:photos/core/configuration.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart' as path;

class DeviceFolderNameFilter implements GalleryItemsFilter {
  final String folderName;

  DeviceFolderNameFilter(this.folderName);

  @override
  bool shouldInclude(File file) {
    return (file.ownerID == null ||
            file.ownerID == Configuration.instance.getUserID()) &&
        path.basename(file.deviceFolder) == folderName;
  }
}
