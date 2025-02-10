import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";

class PeopleChangedEvent extends Event {
  final List<EnteFile>? relevantFiles;
  final PeopleEventType type;
  final String source;
  final PersonEntity? person;

  PeopleChangedEvent({
    this.relevantFiles,
    this.type = PeopleEventType.defaultType,
    this.source = "",
    this.person,
  });

  @override
  String get reason => '$runtimeType{type: ${type.name}, "via": $source}';
}

enum PeopleEventType {
  defaultType,
  removedFilesFromCluster,
  syncDone,
  saveOrEditPerson,
}
