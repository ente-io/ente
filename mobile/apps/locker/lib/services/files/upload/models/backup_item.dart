import "dart:async";
import "dart:io";

import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/files/upload/models/backup_item_status.dart";

class BackupItem {
  final BackupItemStatus status;
  final File file;
  final Collection collection;
  final Completer<EnteFile>? completer;
  final Object? error;

  BackupItem({
    required this.status,
    required this.file,
    required this.collection,
    required this.completer,
    this.error,
  });

  BackupItem copyWith({
    BackupItemStatus? status,
    File? file,
    Collection? collection,
    Completer<EnteFile>? completer,
    Object? error,
  }) {
    return BackupItem(
      status: status ?? this.status,
      file: file ?? this.file,
      collection: collection ?? this.collection,
      completer: completer ?? this.completer,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'BackupItem(status: $status, file: $file, collection: $collection, error: $error)';
  }

  @override
  bool operator ==(covariant BackupItem other) {
    if (identical(this, other)) return true;

    return other.status == status &&
        other.file == file &&
        other.collection == collection &&
        other.completer == completer &&
        other.error == error;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        file.hashCode ^
        collection.hashCode ^
        completer.hashCode;
  }
}
