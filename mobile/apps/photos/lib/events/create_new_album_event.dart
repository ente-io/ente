import "package:photos/events/event.dart";
import "package:photos/models/collection/collection.dart";

class CreateNewAlbumEvent extends Event {
  final Collection collection;

  CreateNewAlbumEvent(this.collection);
}