import 'package:photos/models/search/search_results.dart';

class HolidaySearchResult extends SearchResult {
  final HolidayData holidayData;
  final List<List<int>>
      durationsOFHoliday; //use a method to generate values for this and pass it on to get the files in that duraiton.
  HolidaySearchResult(this.holidayData, this.durationsOFHoliday);
}

class HolidayData {
  final String name;
  final int month;
  final int day;
  const HolidayData(this.name, this.month, this.day);
}
