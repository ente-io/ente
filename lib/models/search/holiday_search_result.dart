import 'package:photos/models/search/search_results.dart';

class HolidaySearchResult extends SearchResult {
  final String name;
  final int month;
  final int day;
  HolidaySearchResult(this.name, this.month, this.day);
}
