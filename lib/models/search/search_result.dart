import 'package:photos/models/file/file.dart';

abstract class SearchResult {
  ResultType type();

  String name();

  EnteFile? previewThumbnail();

  String heroTag() {
    return '${type().toString()}_${name()}';
  }

  List<EnteFile> resultFiles();
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
  event,
}
