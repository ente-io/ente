import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';

class LocalPhotosUpdatedEvent extends Event {
  final List<File> updatedFiles;

  LocalPhotosUpdatedEvent(this.updatedFiles) {
    updatedFiles.sort((a, b) {
      return a.creationTime.compareTo(b.creationTime);
    });
  }
}
