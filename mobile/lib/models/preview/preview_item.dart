import "dart:async";

import "package:photos/models/file/file.dart";
import "package:photos/models/preview/preview_item_status.dart";

class PreviewItem {
  final PreviewItemStatus status;
  final EnteFile file;
  final int collectionID;
  final int retryCount;
  final Object? error;

  PreviewItem({
    required this.status,
    required this.file,
    required this.collectionID,
    this.retryCount = 0,
    this.error,
  });

  PreviewItem copyWith({
    PreviewItemStatus? status,
    EnteFile? file,
    int? collectionID,
    Completer<EnteFile>? completer,
    int? retryCount,
    Object? error,
  }) {
    return PreviewItem(
      status: status ?? this.status,
      file: file ?? this.file,
      collectionID: collectionID ?? this.collectionID,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'PreviewItem(status: $status, file: $file, retryCount: $retryCount, collectionID: $collectionID, error: $error)';
  }

  @override
  bool operator ==(covariant PreviewItem other) {
    if (identical(this, other)) return true;

    return other.status == status &&
        other.file == file &&
        other.retryCount == retryCount &&
        other.collectionID == collectionID &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        retryCount.hashCode ^
        file.hashCode ^
        collectionID.hashCode;
  }
}
