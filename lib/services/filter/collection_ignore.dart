import "package:photos/models/file.dart";
import "package:photos/services/filter/filter.dart";

class CollectionsIgnoreFilter extends Filter {
  final Set<int> collectionIDs;

  Set<int>? _ignoredUploadIDs;

  CollectionsIgnoreFilter(this.collectionIDs) : super();

  void init(List<File> files) {
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
  bool filter(File file) {
    return file.isUploaded &&
        !_ignoredUploadIDs!.contains(file.uploadedFileID!);
  }
}
