import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";

abstract class HierarchicalSearchFilter {
  String name();
  IconData? icon();
  int relevance();
  bool isMatch(EnteFile file);
  Set<int> getMatchedUploadedIDs();
}
