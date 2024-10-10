import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/location_service.dart";

class LocationFilter extends HierarchicalSearchFilter {
  final LocationTag locationTag;
  final int occurrence;

  LocationFilter({
    required this.locationTag,
    required this.occurrence,
  });

  @override
  String name() {
    return locationTag.name;
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  bool isMatch(EnteFile file) {
    if (!file.hasLocation) return false;
    return isFileInsideLocationTag(
      locationTag.centerPoint,
      file.location!,
      locationTag.radius,
    );
  }

  @override
  Set<int> getMatchedUploadedIDs() {
    return matchedUploadedIDs;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    if (other is LocationFilter) {
      return other.locationTag.radius.toString() +
              other.locationTag.centerPoint.toString() +
              other.locationTag.name ==
          locationTag.radius.toString() +
              locationTag.centerPoint.toString() +
              locationTag.name;
    }
    // (other is LocationFilter) can be false and this.resultType() can be same as
    // other.resultType() if other is a TopLevelGenericFilter of resultType
    // ResultType.location
    return resultType() == other.resultType() && other.name() == name();
  }

  @override
  IconData icon() {
    return Icons.location_pin;
  }

  @override
  ResultType resultType() {
    return ResultType.location;
  }
}
