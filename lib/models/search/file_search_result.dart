import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_result.dart';

class FileSearchResult extends SearchResult {
  final File file;

  FileSearchResult(this.file);

  @override
  String name() {
    return file.displayName;
  }

  @override
  ResultType type() {
    return ResultType.file;
  }

  @override
  File previewThumbnail() {
    return file;
  }

  @override
  List<File> resultFiles() {
    // for fileSearchResult, the file detailed page view will be opened
    throw UnimplementedError();
  }
}
