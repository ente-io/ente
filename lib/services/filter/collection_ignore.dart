import "package:photos/models/file.dart";
import "package:photos/services/filter/filter.dart";

// CollectionsIgnoreFilter will filter out files that are in present in the
// given collections. This is useful for filtering out files that are in archive
// or hidden collections from home page and other places
class CollectionsIgnoreFilter extends Filter {
  final Set<int> collectionIDs;

  Set<int>? _ignoredUploadIDs;

  CollectionsIgnoreFilter(this.collectionIDs, List<EnteFile> files) : super() {
    init(files);
  }

  void init(List<EnteFile> files) {
    _ignoredUploadIDs = {};
    if (collectionIDs.isEmpty) return;
    for (var file in files) {
      if (file.collectionID != null &&
          file.isUploaded &&
          collectionIDs.contains(file.collectionID!)) {
        _ignoredUploadIDs!.add(file.uploadedFileID!);
      }
    }
  }

  @override
  bool filter(EnteFile file) {
    if (!file.isUploaded) {
      // if file is in one of the ignored collections, filter it out. This check
      // avoids showing un-uploaded files that are going to be uploaded to one of
      // the ignored collections
      if (file.collectionID != null &&
          collectionIDs.contains(file.collectionID!)) {
        return false;
      }
      return true;
    }
    return !_ignoredUploadIDs!.contains(file.uploadedFileID!);
  }
}
