import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/search_types.dart";

class FaceFilter extends HierarchicalSearchFilter {
  final String? personId;
  final String? clusterId;

  ///If name is not available, use string of memories count instead. It should be
  ///of the same format as SearchResult.name();
  final String faceName;
  final EnteFile faceFile;
  final int occurrence;

  FaceFilter({
    required this.personId,
    required this.clusterId,
    required this.faceName,
    required this.faceFile,
    required this.occurrence,
  }) : assert(
          personId != null || clusterId != null,
          "personId or clusterId must be provided",
        );

  @override
  String name() {
    return faceName;
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  IconData? icon() {
    throw UnimplementedError(
      "FaceFilter does not need an icon, the face crop should be used instead",
    );
  }

  @override
  bool isMatch(EnteFile file) {
    return false;
  }

  @override
  Set<int> getMatchedUploadedIDs() {
    return matchedUploadedIDs;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    if (other is FaceFilter) {
      return other.personId == personId && other.clusterId == clusterId;
    }
    // (other is FaceFilter) can be false and this.resultType() can be same as
    // other.resultType() if other is a TopLevelGenericFilter of resultType
    // ResultType.faces
    return resultType() == other.resultType() && other.name() == name();
  }

  @override
  ResultType resultType() {
    return ResultType.faces;
  }
}
