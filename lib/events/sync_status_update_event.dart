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
  started_first_gallery_import,
  completed_first_gallery_import,
  applying_remote_diff,
  preparing_for_upload,
  in_progress,
  paused,
  completed_backup,
  error,
}
