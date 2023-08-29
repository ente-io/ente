import 'package:photos/models/file/file.dart';
import "package:photos/services/filter/filter.dart";
import "package:photos/services/ignored_files_service.dart";

// UploadIgnoreFilter hides the unuploaded files that are ignored from for
// upload
class UploadIgnoreFilter extends Filter {
  Map<String, String> idToReasonMap;

  UploadIgnoreFilter(this.idToReasonMap) : super();

  @override
  bool filter(EnteFile file) {
    // Already uploaded files pass the filter
    if (file.isUploaded) return true;
    return !IgnoredFilesService.instance.shouldSkipUpload(idToReasonMap, file);
  }
}
