import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class LocationSearchResult extends SearchResult {
  final String location;
  final List<File> files;

  LocationSearchResult(this.location, this.files);

  @override
  String name() {
    return location;
  }

  @override
  ResultType type() {
    return ResultType.location;
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
