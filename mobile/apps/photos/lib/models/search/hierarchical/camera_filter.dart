import "package:flutter/material.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

class CameraFilter extends HierarchicalSearchFilter {
  final String cameraLabel;
  final int occurrence;

  CameraFilter({
    required this.cameraLabel,
    required this.occurrence,
    super.filterTypeName = "cameraFilter",
    super.matchedUploadedIDs,
  });

  @override
  String name() {
    return cameraLabel;
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  bool isMatch(EnteFile file) {
    return file.cameraLabel == cameraLabel;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    if (other is CameraFilter) {
      return other.cameraLabel == cameraLabel;
    }
    return false;
  }

  @override
  IconData? icon() {
    return Icons.photo_camera_outlined;
  }
}
