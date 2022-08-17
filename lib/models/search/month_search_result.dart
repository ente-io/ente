import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class MonthSearchResult extends SearchResult {
  final String month;
  final List<File> files;
  MonthSearchResult(this.month, this.files);
}

class MonthWihMonthNumber {
  final String month;
  final int monthNumber;
  MonthWihMonthNumber(this.month, this.monthNumber);
}
