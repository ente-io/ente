import "package:photos/events/event.dart";

class FileCaptionUpdatedEvent extends Event {
  final int fileGeneratedID;

  FileCaptionUpdatedEvent(this.fileGeneratedID);
}
