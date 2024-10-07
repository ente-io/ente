import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/search_types.dart";

///Not necessary that all top level filters in hierarchical search have to be
///a [TopLevelGenericFilter].
class TopLevelGenericFilter extends HierarchicalSearchFilter {
  final String filterName;
  final int occurrence;
  final IconData? filterIcon;
  final ResultType filterResultType;

  TopLevelGenericFilter({
    required this.filterName,
    required this.occurrence,
    required this.filterResultType,
    required super.matchedUploadedIDs,
    this.filterIcon,
  });

  @override
  bool isMatch(EnteFile file) {
    throw UnimplementedError(
      "isMatch is not ment to be called by design for TopLevelGenericFilter. "
      "isMatch is used for checking if files match the filter and then to add "
      "the file's uploaded fileIDs to the filter's matchingFileIDs list. For "
      "top level filters, matchingFileIDs should be set when the filter is "
      "initialised since the results are passed to the widget where it's "
      "initialised.",
    );
  }

  @override
  Set<int> getMatchedUploadedIDs() {
    return matchedUploadedIDs;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    return other.resultType() == filterResultType && other.name() == name();
  }

  @override
  String name() {
    return filterName;
  }

  @override
  IconData? icon() {
    return filterIcon;
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  ResultType resultType() {
    return filterResultType;
  }
}
