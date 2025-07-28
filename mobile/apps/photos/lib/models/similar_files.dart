import "package:photos/models/file/file.dart";

class SimilarFiles {
  final List<EnteFile> files;
  final int totalSize;
  final double furthestDistance;

  SimilarFiles(
    this.files,
    this.totalSize,
    this.furthestDistance,
  );

  @override
  String toString() =>
      'SimilarFiles(files: $files, size: $totalSize, distance: $furthestDistance)';
}
