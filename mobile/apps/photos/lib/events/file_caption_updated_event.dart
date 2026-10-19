import "package:photos/events/event.dart";

class FileCaptionUpdatedEvent extends Event {
  final int fileGeneratedID;
  final int uploadedFileID;
  final String? caption;

  FileCaptionUpdatedEvent(
    this.fileGeneratedID, {
    required this.uploadedFileID,
    required this.caption,
  });
}
