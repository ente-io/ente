import 'package:photos/events/files_updated_event.dart';

class LocalPhotosUpdatedEvent extends FilesUpdatedEvent {
  LocalPhotosUpdatedEvent(super.updatedFiles, {type, required source})
      : super(
          type: type ?? EventType.addedOrUpdated,
          source: source ?? "",
        );
}
