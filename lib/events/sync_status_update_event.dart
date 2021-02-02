import 'package:photos/events/event.dart';

class SyncStatusUpdate extends Event {
  final int completed;
  final int total;
  final bool wasStopped;
  final SyncStatus status;
  final String reason;
  final Error error;

  SyncStatusUpdate(
    this.status, {
    this.completed,
    this.total,
    this.wasStopped = false,
    this.reason = "",
    this.error,
  });
}

enum SyncStatus {
  applying_local_diff,
  applying_remote_diff,
  preparing_for_upload,
  in_progress,
  paused,
  completed,
  error,
}
