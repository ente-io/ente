import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class HolidaySearchResult extends SearchResult {
  final String holidayName;
  final List<File> files;
  HolidaySearchResult(this.holidayName, this.files);
}

class HolidayDataWithDuration {
  final String holidayName;
  final List<List<int>> durationsOFHoliday;
  HolidayDataWithDuration(this.holidayName, this.durationsOFHoliday);
}

class HolidayData {
  final String name;
  final int month;
  final int day;
  const HolidayData(this.name, this.month, this.day);
}
