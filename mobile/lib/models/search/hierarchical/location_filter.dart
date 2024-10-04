import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
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
      return other.locationTag.name == locationTag.name &&
          other.locationTag.radius == locationTag.radius;
    }
    return false;
  }

  @override
  IconData icon() {
    return Icons.location_pin;
  }
}
