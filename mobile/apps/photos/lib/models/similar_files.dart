import "package:photos/models/file/file.dart";

class SimilarFiles {
  final List<EnteFile> files;
  final int totalSize;
  final double similarityScore;

  SimilarFiles(
    this.files,
    this.totalSize,
    this.similarityScore,
  );

  @override
  String toString() => 'SimilarFiles(files: $files, size: $totalSize)';
}
