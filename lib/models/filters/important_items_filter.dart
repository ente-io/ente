import 'dart:io';

import 'package:path/path.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';

class ImportantItemsFilter implements GalleryItemsFilter {
  final _importantPaths = Configuration.instance.getPathsToBackUp();

  @override
  bool shouldInclude(File file) {
    if (file.uploadedFileID != null) {
      return true;
    }
    if (file.deviceFolder == null) {
      return false;
    }
    final String folder = basename(file.deviceFolder!);
    if (_importantPaths.isEmpty && Platform.isAndroid) {
      return folder == "Camera" ||
          folder == "Recents" ||
          folder == "DCIM" ||
          folder == "Download" ||
          folder == "Screenshot";
    }
    return _importantPaths.contains(folder);
  }
}
