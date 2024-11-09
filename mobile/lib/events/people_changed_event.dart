import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";

class PeopleRemoteFeedbackEvent extends Event {
  final String source;

  PeopleRemoteFeedbackEvent({
    this.source = "",
  });

  @override
  String get reason => '$runtimeType{"via": $source}';
}

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
