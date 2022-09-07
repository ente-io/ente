// @dart=2.9

import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class HolidaySearchResult extends SearchResult {
  final String holidayName;
  final List<File> files;
  HolidaySearchResult(this.holidayName, this.files);
}

class HolidayData {
  final String name;
  final int month;
  final int day;
  const HolidayData(this.name, this.month, this.day);
}
