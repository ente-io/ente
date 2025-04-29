import 'package:photos/models/file/file.dart';
import "package:photos/services/filter/filter.dart";

// CollectionsOrHashIgnoreFilter will filter out all files that are in present in the
// given collections collectionIDs. This is useful for filtering out files that are in archive
// or hidden collections from home page and other places. Based on flag, it will also filter out
// shared files if the user already as another file with the same hash.
class CollectionsAndSavedFileFilter extends Filter {
  final Set<int> collectionIDs;
  final bool ignoreSavedFiles;
  final int ownerID;

  Set<int>? _ignoredUploadIDs;
  Set<String> ownedFileHashes = {};

  CollectionsAndSavedFileFilter(
    this.collectionIDs,
    this.ownerID,
    List<EnteFile> files,
    this.ignoreSavedFiles,
  ) : super() {
    init(files);
  }

  void init(List<EnteFile> files) {
    _ignoredUploadIDs = {};
    for (var file in files) {
      if (file.collectionID != null && file.isUploaded) {
        if (collectionIDs.contains(file.collectionID!)) {
          _ignoredUploadIDs!.add(file.uploadedFileID!);
        } else if (ignoreSavedFiles &&
            file.ownerID == ownerID &&
            (file.hash ?? '').isNotEmpty) {
          ownedFileHashes.add(file.hash!);
        }
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
    if (_ignoredUploadIDs!.contains(file.uploadedFileID!)) {
      return false; // this file should be filtered out
    }
    if (ignoreSavedFiles &&
        file.ownerID != ownerID &&
        (file.hash ?? '').isNotEmpty) {
      // if the file is shared and the user already has a file with the same hash
      // then filter it out by returning false
      return !ownedFileHashes.contains(file.hash!);
    }
    return true;
  }
}
