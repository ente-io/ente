import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";

int kMostRelevantFilter = 10000;
int kLeastRelevantFilter = -1;

abstract class HierarchicalSearchFilter {
  final Set<int> matchedUploadedIDs = {};

  String name();
  IconData? icon();
  int relevance();
  bool isMatch(EnteFile file);
  Set<int> getMatchedUploadedIDs();
  bool isSameFilter(HierarchicalSearchFilter other);
}
