import 'package:photos/models/file/file.dart';
import "package:photos/services/filter/filter.dart";

// DedupeUploadIDFilter will filter out files where were previously filtered
// during the same filtering session
class DedupeUploadIDFilter extends Filter {
  final Set<int> trackedUploadIDs = {};

  @override
  bool filter(EnteFile file) {
    if (!file.isUploaded) {
      return true;
    }
    if (trackedUploadIDs.contains(file.uploadedFileID!)) {
      return false;
    }
    trackedUploadIDs.add(file.uploadedFileID!);
    return true;
  }
}
