import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";

class PeopleChangedEvent extends Event {
  final List<EnteFile>? relevantFiles;
  final List<String>? relevantFaceIDs;
  final PeopleEventType type;
  final String source;
  final PersonEntity? person;

  PeopleChangedEvent({
    this.relevantFiles,
    this.relevantFaceIDs,
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
  removedFaceFromCluster,
  syncDone,
  saveOrEditPerson,
  addedClusterToPerson,
}
