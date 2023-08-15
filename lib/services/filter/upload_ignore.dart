import "package:photos/models/file.dart";
import "package:photos/services/filter/filter.dart";
import "package:photos/services/ignored_files_service.dart";

// UploadIgnoreFilter hides the unuploaded files that are ignored from for
// upload
class UploadIgnoreFilter extends Filter {
  Set<String> ignoredIDs;

  UploadIgnoreFilter(this.ignoredIDs) : super();

  @override
  bool filter(File file) {
    // Already uploaded files pass the filter
    if (file.isUploaded) return true;
    return !IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, file);
  }
}
