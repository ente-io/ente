import "package:photos/models/file/file.dart";
import "package:photos/services/filter/db_filters.dart";

final homeGalleryFilters = DBFilterOptions(
  dedupeUploadID: true,
  ignoreSavedFiles: true,
  onlyUploadedFiles: false,
);
Future<List<EnteFile>> merge({
  required List<EnteFile> localFiles,
  required List<EnteFile> remoteFiles,
  DBFilterOptions? filterOptions,
}) {
  final List<EnteFile> mergedFiles = [];
  int i = 0;
  int j = 0;
  final int localLength = localFiles.length;
  final int remoteLength = remoteFiles.length;

  while (i < localLength && j < remoteLength) {
    if (localFiles[i].creationTime! >= remoteFiles[j].creationTime!) {
      mergedFiles.add(localFiles[i++]);
    } else {
      mergedFiles.add(remoteFiles[j++]);
    }
  }
  // Add remaining elements (only one of these loops will actually run)
  mergedFiles.addAll(localFiles.sublist(i));
  mergedFiles.addAll(remoteFiles.sublist(j));
  if (filterOptions != null) {
    return applyDBFilters(mergedFiles, filterOptions);
  }
  return Future.value(mergedFiles);
}
