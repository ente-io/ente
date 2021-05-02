import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';

class FilesUpdatedEvent extends Event {
  final List<File> updatedFiles;
  final EventType type;

  FilesUpdatedEvent(
    this.updatedFiles, {
    this.type = EventType.added_or_updated,
  });
}

enum EventType {
  added_or_updated,
  deleted,
}
