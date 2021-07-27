import 'dart:io';

import 'package:path/path.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';

class ImportantItemsFilter implements GalleryItemsFilter {
  final _importantPaths = Configuration.instance.getPathsToBackUp();

  @override
  bool shouldInclude(File file) {
    if (_importantPaths.isEmpty) {
      if (Platform.isAndroid) {
        if (file.uploadedFileID != null) {
          return true;
        }
        final String folder = basename(file.deviceFolder);
        return folder == "Camera" ||
            folder == "Recents" ||
            folder == "DCIM" ||
            folder == "Download" ||
            folder == "Screenshot";
      } else {
        return true;
      }
    }
    if (file.uploadedFileID != null) {
      return true;
    }
    final folder = basename(file.deviceFolder);
    return _importantPaths.contains(folder);
  }
}
