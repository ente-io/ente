import "package:photos/events/event.dart";

class FileCaptionUpdatedEvent extends Event {
  final String fileTag;

  FileCaptionUpdatedEvent(this.fileTag);
}
