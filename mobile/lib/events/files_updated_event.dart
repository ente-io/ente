import 'package:photos/events/event.dart';
import 'package:photos/models/file/file.dart';

class FilesUpdatedEvent extends Event {
  final List<EnteFile> updatedFiles;
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
  coverChanged,
  peopleChanged,
  peopleClusterChanged,
}
