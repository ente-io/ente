import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_result.dart';

class MonthSearchResult extends SearchResult {
  final String month;
  final List<File> files;

  MonthSearchResult(this.month, this.files);

  @override
  String name() {
    return month;
  }

  @override
  ResultType type() {
    return ResultType.month;
  }

  @override
  File previewThumbnail() {
    return files.first;
  }

  @override
  List<File> resultFiles() {
    return files;
  }
}

class MonthData {
  final String name;
  final int monthNumber;

  MonthData(this.name, this.monthNumber);
}
