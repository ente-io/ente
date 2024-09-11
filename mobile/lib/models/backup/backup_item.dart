import "dart:async";

import "package:photos/models/backup/backup_item_status.dart";
import "package:photos/models/file/file.dart";

class BackupItem {
  final BackupItemStatus status;
  final EnteFile file;
  final int collectionID;
  final Completer<EnteFile>? completer;
  final Object? error;

  BackupItem({
    required this.status,
    required this.file,
    required this.collectionID,
    required this.completer,
    this.error,
  });

  BackupItem copyWith({
    BackupItemStatus? status,
    EnteFile? file,
    int? collectionID,
    Completer<EnteFile>? completer,
    Object? error,
  }) {
    return BackupItem(
      status: status ?? this.status,
      file: file ?? this.file,
      collectionID: collectionID ?? this.collectionID,
      completer: completer ?? this.completer,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'BackupItem(status: $status, file: $file, collectionID: $collectionID, error: $error)';
  }

  @override
  bool operator ==(covariant BackupItem other) {
    if (identical(this, other)) return true;

    return other.status == status &&
        other.file == file &&
        other.collectionID == collectionID &&
        other.completer == completer &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        file.hashCode ^
        collectionID.hashCode ^
        completer.hashCode;
  }
}
