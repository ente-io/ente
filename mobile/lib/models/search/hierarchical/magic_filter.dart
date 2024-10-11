import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/search_types.dart";

class MagicFilter extends HierarchicalSearchFilter {
  @override
  Set<int> getMatchedUploadedIDs() {
    // TODO: implement getMatchedUploadedIDs
    throw UnimplementedError();
  }

  @override
  IconData? icon() {
    // TODO: implement icon
    throw UnimplementedError();
  }

  @override
  bool isMatch(EnteFile file) {
    // TODO: implement isMatch
    throw UnimplementedError();
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    // TODO: implement isSameFilter
    throw UnimplementedError();
  }

  @override
  String name() {
    // TODO: implement name
    throw UnimplementedError();
  }

  @override
  int relevance() {
    // TODO: implement relevance
    throw UnimplementedError();
  }

  @override
  ResultType resultType() {
    // TODO: implement resultType
    throw UnimplementedError();
  }
}
