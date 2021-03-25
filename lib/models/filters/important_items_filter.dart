import 'dart:io';

import 'package:photos/core/configuration.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/file.dart';
import 'package:path/path.dart';

class ImportantItemsFilter implements GalleryItemsFilter {
  final importantPaths = Configuration.instance.getPathsToBackUp();

  @override
  bool shouldInclude(File file) {
    if (file.uploadedFileID != null) {
      return true;
    }
    final String folder = basename(file.deviceFolder);
    return importantPaths.contains(folder);
  }
}
