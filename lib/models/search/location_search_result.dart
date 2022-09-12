import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class LocationSearchResult extends SearchResult {
  final String location;
  final List<File> files;

  LocationSearchResult(this.location, this.files);
}
