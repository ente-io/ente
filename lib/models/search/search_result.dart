import 'package:photos/models/file.dart';
import "package:photos/models/search/search_types.dart";

abstract class SearchResult {
  ResultType type();

  String name();

  File? previewThumbnail();

  String heroTag() {
    return '${type().toString()}_${name()}';
  }

  List<File> resultFiles();
}
