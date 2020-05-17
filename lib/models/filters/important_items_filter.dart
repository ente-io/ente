import 'dart:io';

import 'package:photos/models/filters/gallery_items_filter.dart';
import 'package:photos/models/photo.dart';
import 'package:path/path.dart';

class ImportantItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(Photo photo) {
    if (Platform.isAndroid) {
      final String folder = basename(photo.deviceFolder);
      return folder == "Camera" ||
          folder == "DCIM" ||
          folder == "Download" ||
          folder == "Screenshot";
    } else {
      return true;
    }
  }
}
