import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_results.dart';

class HolidaySearchResult extends SearchResult {
  final String holidayName;
  final List<File> files;

  HolidaySearchResult(this.holidayName, this.files);

  @override
  String name() {
    return holidayName;
  }

  @override
  ResultType type() {
    return ResultType.event;
  }

  @override
  File previewThumbnail() {
    return files[0];
  }

  @override
  List<File> resultFiles() {
    return files;
  }
}

class HolidayData {
  final String name;
  final int month;
  final int day;

  const HolidayData(this.name, {required this.month, required this.day});
}
