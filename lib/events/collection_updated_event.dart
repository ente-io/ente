import 'package:photos/events/event.dart';
import 'package:photos/events/files_updated_event.dart';

class CollectionUpdatedEvent extends FilesUpdatedEvent {
  final int collectionID;

  CollectionUpdatedEvent(this.collectionID, updatedFiles) : super(updatedFiles);
}
