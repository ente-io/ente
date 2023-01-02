import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';

class FilesUpdatedEvent extends Event {
  final List<File> updatedFiles;
  final EventType type;
  final String source;

  FilesUpdatedEvent(
    this.updatedFiles, {
    this.type = EventType.addedOrUpdated,
    this.source = "",
  });

  @override
  String get reason => '$runtimeType{type: ${type.name}, "via": $source}';
}

enum EventType {
  addedOrUpdated,
  deletedFromDevice,
  deletedFromRemote,
  deletedFromEverywhere,
  archived,
  unarchived,
  hide,
  unhide,
}
