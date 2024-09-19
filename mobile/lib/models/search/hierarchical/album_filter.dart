import "package:flutter/material.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

class AlbumFilter implements HierarchicalSearchFilter {
  final String albumName;

  AlbumFilter(this.albumName);

  @override
  String name() {
    return albumName;
  }

  @override
  IconData icon() {
    return Icons.photo_library_outlined;
  }
}
