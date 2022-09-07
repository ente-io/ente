// @dart=2.9

import 'package:photos/events/event.dart';

class SyncStatusUpdate extends Event {
  final int completed;
  final int total;
  final bool wasStopped;
  final SyncStatus status;
  final String reason;
  final Error error;
  int timestamp;

  SyncStatusUpdate(
    this.status, {
    this.completed,
    this.total,
    this.wasStopped = false,
    this.reason = "",
    this.error,
  }) {
    timestamp = DateTime.now().microsecondsSinceEpoch;
  }

  @override
  String toString() {
    return 'SyncStatusUpdate(completed: $completed, total: $total, wasStopped: $wasStopped, status: $status, reason: $reason, error: $error)';
  }
}

enum SyncStatus {
  startedFirstGalleryImport,
  completedFirstGalleryImport,
  applyingRemoteDiff,
  preparingForUpload,
  inProgress,
  paused,
  completedBackup,
  error,
}
