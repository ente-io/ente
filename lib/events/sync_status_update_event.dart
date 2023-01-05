import 'package:photos/events/event.dart';

class SyncStatusUpdate extends Event {
  final SyncStatus status;
  final int? completed;
  final int? total;
  final bool wasStopped;
  @override
  final String reason;
  final Error? error;
  late int timestamp;

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
