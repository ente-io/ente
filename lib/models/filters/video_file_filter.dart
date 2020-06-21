import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/filters/gallery_items_filter.dart';

class VideoFileFilter implements GalleryItemsFilter {
  @override
  bool shouldInclude(File file) {
    return file.fileType == FileType.video;
  }
}
