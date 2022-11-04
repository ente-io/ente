// @dart=2.9

import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';

class FilesUpdatedEvent extends Event {
  final List<File> updatedFiles;
  final EventType type;

  FilesUpdatedEvent(
    this.updatedFiles, {
    this.type = EventType.addedOrUpdated,
  });
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
