import 'package:photos/events/event.dart';

class SyncStatusUpdate extends Event {
  final int completed;
  final int total;
  final bool hasError;
  final bool wasStopped;

  SyncStatusUpdate({
    this.completed,
    this.total,
    this.hasError = false,
    this.wasStopped = false,
  });
}
