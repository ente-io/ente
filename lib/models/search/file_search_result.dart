// @dart=2.9

import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class FileSearchResult extends SearchResult {
  final File file;

  FileSearchResult(this.file);
}
