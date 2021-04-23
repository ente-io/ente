import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';

class FilesUpdatedEvent extends Event {
  final List<File> updatedFiles;

  FilesUpdatedEvent(this.updatedFiles);
}