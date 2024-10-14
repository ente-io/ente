import 'package:photos/models/file/file.dart';
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import 'package:photos/models/search/search_result.dart';
import "package:photos/models/search/search_types.dart";

class FileSearchResult extends SearchResult {
  final EnteFile file;

  FileSearchResult(this.file);

  @override
  String name() {
    return file.displayName;
  }

  @override
  ResultType type() {
    return ResultType.file;
  }

  @override
  EnteFile previewThumbnail() {
    return file;
  }

  @override
  List<EnteFile> resultFiles() {
    // for fileSearchResult, the file detailed page view will be opened
    throw UnimplementedError();
  }

  @override
  HierarchicalSearchFilter getHierarchicalSearchFilter() {
    throw UnimplementedError();
  }
}
