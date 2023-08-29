import 'package:photos/models/file/file.dart';

class FileLoadResult {
  final List<EnteFile> files;
  final bool hasMore;

  FileLoadResult(this.files, this.hasMore);
}
