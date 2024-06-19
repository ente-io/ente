import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";

class PeopleChangedEvent extends Event {
  final List<EnteFile>? relevantFiles;
  final PeopleEventType type;
  final String source;

  PeopleChangedEvent({
    this.relevantFiles, 
    this.type = PeopleEventType.defaultType,
    this.source = "",
  });

  @override
  String get reason => '$runtimeType{type: ${type.name}, "via": $source}';
}

enum PeopleEventType {
  defaultType,
  removedFilesFromCluster,
  syncDone,
}