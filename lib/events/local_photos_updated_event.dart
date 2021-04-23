import 'package:photos/events/event.dart';
import 'package:photos/events/files_updated_event.dart';

class LocalPhotosUpdatedEvent extends FilesUpdatedEvent {
  LocalPhotosUpdatedEvent(updatedFiles) : super(updatedFiles);
}
