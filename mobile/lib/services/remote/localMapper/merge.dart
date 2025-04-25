import "package:photos/models/file/file.dart";

List<EnteFile> merge({
  required List<EnteFile> localFiles,
  required List<EnteFile> remoteFiles,
}) {
  final List<EnteFile> mergedFiles = [];
  int i = 0;
  int j = 0;
  final int localLength = localFiles.length;
  final int remoteLength = remoteFiles.length;

  // Since there are no duplicates, we can merge without checking
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

  return mergedFiles;
}
