import 'package:photos/utils/date_time_util.dart';

class YearsData {
  final List<YearData> yearsData = [];
  YearsData._privateConstructor() {
    for (int year = 1970; year <= currentYear; year++) {
      yearsData.add(
        YearData(year.toString(), year, [
          DateTime(year).microsecondsSinceEpoch,
          DateTime(year + 1).microsecondsSinceEpoch,
        ]),
      );
    }
  }
  static final YearsData instance = YearsData._privateConstructor();
}

class YearData {
  final String yearInString;
  final int yearInInt;
  final List<int> duration;
  YearData(this.yearInString, this.yearInInt, this.duration);
}
