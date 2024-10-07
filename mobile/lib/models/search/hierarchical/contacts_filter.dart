import "package:flutter/material.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/search_types.dart";

class ContactsFilter extends HierarchicalSearchFilter {
  final User user;
  final int occurrence;

  ContactsFilter({
    required this.user,
    required this.occurrence,
  });

  @override
  String name() {
    if (user.name == null || user.name!.isEmpty) {
      return user.email;
    }
    return user.name!;
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  bool isMatch(EnteFile file) {
    return file.ownerID == user.id;
  }

  @override
  Set<int> getMatchedUploadedIDs() {
    return matchedUploadedIDs;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    return resultType() == other.resultType() && other.name() == name();
  }

  @override
  IconData? icon() {
    return Icons.person_outlined;
  }

  @override
  ResultType resultType() {
    return ResultType.shared;
  }
}
