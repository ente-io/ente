import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";

extension FileTypeExtension on FileType {
  IconData get icon {
    switch (this) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.videocam;
      case FileType.livePhoto:
        return Icons.album_outlined;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class FileTypeFilter extends HierarchicalSearchFilter {
  final FileType fileType;
  final int occurrence;

  FileTypeFilter({
    required this.fileType,
    required this.occurrence,
  });

  @override
  String name() {
    return fileType.name;
  }

  @override
  IconData icon() {
    return fileType.icon;
  }

  @override
  int relevance() {
    return occurrence;
  }

  @override
  bool isMatch(EnteFile file) {
    return file.fileType == fileType;
  }

  @override
  Set<int> getMatchedUploadedIDs() {
    return matchedUploadedIDs;
  }

  @override
  bool isSameFilter(HierarchicalSearchFilter other) {
    if (other is FileTypeFilter) {
      return other.fileType == fileType;
    }
    return false;
  }
}
