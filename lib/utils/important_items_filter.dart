import 'dart:io';

import 'package:myapp/models/photo.dart';
import 'package:myapp/utils/gallery_items_filter.dart';
import 'package:path/path.dart';

class ImportantItemsFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(Photo photo) {
    if (Platform.isAndroid) {
      final String folder = basename(photo.pathName);
      return folder == "Camera" ||
          folder == "DCIM" ||
          folder == "Download" ||
          folder == "Screenshot";
    } else {
      return true;
    }
  }
}
