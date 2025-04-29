import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";

class FileUploadedEvent extends Event {
  final EnteFile file;

  FileUploadedEvent(this.file);
}
