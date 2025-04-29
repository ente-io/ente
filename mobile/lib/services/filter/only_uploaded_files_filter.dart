import "package:photos/models/file/file.dart";
import "package:photos/services/filter/filter.dart";

class OnlyUploadedFilesFilter extends Filter {
  @override
  bool filter(EnteFile file) {
    return file.isUploaded;
  }
}
