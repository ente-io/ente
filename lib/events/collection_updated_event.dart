// @dart=2.9

import 'package:photos/events/files_updated_event.dart';

class CollectionUpdatedEvent extends FilesUpdatedEvent {
  final int collectionID;

  CollectionUpdatedEvent(this.collectionID, updatedFiles, source, {type})
      : super(
          updatedFiles,
          type: type ?? EventType.addedOrUpdated,
          source: source ?? "",
        );
}
