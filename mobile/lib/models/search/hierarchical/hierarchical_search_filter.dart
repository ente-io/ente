import "package:flutter/widgets.dart";
import "package:photos/models/file/file.dart";

int kMostRelevantFilter = 10000;
int kLeastRelevantFilter = -1;

abstract class HierarchicalSearchFilter {
  //These matches should be from list of all files in db and not just all files in
  //gallery if we plan to use this cache for faster filtering when adding/removing
  //applied filters.
  final Set<int> matchedUploadedIDs = {};

  String name();
  IconData? icon();
  int relevance();
  bool isMatch(EnteFile file);
  Set<int> getMatchedUploadedIDs();
  bool isSameFilter(HierarchicalSearchFilter other);
}
