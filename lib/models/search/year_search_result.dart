import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_result.dart';

class YearSearchResult extends SearchResult {
  final String year;
  final List<File> files;

  YearSearchResult(this.year, this.files);

  @override
  String name() {
    return year;
  }

  @override
  ResultType type() {
    return ResultType.year;
  }

  @override
  File previewThumbnail() {
    return files.first;
  }

  @override
  List<File> resultFiles() {
    return files;
  }
}
