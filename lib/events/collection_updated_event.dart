import 'package:photos/events/event.dart';

class CollectionUpdatedEvent extends Event {
  final int collectionID;

  CollectionUpdatedEvent({this.collectionID});
}
