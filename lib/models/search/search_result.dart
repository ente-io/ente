import 'package:photos/models/file.dart';

abstract class SearchResult {
  ResultType type();

  String name();

  File previewThumbnail();

  String heroTag() {
    return '${type().toString()}_${name()}';
  }

  List<File> resultFiles();
}

enum ResultType {
  collection,
  file,
  location,
  month,
  year,
  fileType,
  fileExtension,
  fileCaption,
  event
}
