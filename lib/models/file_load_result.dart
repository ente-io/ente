import 'package:photos/models/file.dart';

class FileLoadResult {
  final List<File> files;
  final bool hasMore;

  FileLoadResult(this.files, this.hasMore);
}
