// @dart=2.9

import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class MonthSearchResult extends SearchResult {
  final String month;
  final List<File> files;
  MonthSearchResult(this.month, this.files);
}

class MonthData {
  final String name;
  final int monthNumber;
  MonthData(this.name, this.monthNumber);
}
