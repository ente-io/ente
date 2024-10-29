import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

class OnlyThemFilter extends HierarchicalSearchFilter {
  final List<FaceFilter> faceFilters;
  final List<FaceFilter> faceFiltersToAvoid;
  final int occurrence;

  OnlyThemFilter({
    required this.faceFilters,
    required this.faceFiltersToAvoid,
    required this.occurrence,
    super.filterTypeName = "onlyThemFilter",
  });

  @override
  String name() {
    return "Only them";
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  IconData? icon() {
    return Icons.face;
  }

  @override
  bool isMatch(EnteFile file) {
    throw UnimplementedError();
  }

  @override
  Set<int> getMatchedUploadedIDs() {
    return matchedUploadedIDs;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    if (other is OnlyThemFilter) {
      return true;
    }
    return false;
  }
}
