import "package:photos/models/file/file.dart";

class SimilarFiles {
  final List<EnteFile> files;
  final Set<int> fileIds;
  final double furthestDistance;

  SimilarFiles(
    this.files,
    this.furthestDistance,
  )      : fileIds = files.map((file) => file.uploadedFileID!).toSet();

  int get totalSize =>
      files.fold(0, (sum, file) => sum + (file.fileSize ?? 0));

  @override
  String toString() =>
      'SimilarFiles(files: $files, size: $totalSize, distance: $furthestDistance)';

  void removeFile(EnteFile file) {
    files.remove(file);
    fileIds.remove(file.uploadedFileID);
  }
}
