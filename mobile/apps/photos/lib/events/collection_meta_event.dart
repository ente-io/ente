import 'package:photos/events/event.dart';

class CollectionMetaEvent extends Event {
  final int id;
  final CollectionMetaEventType type;

  CollectionMetaEvent(this.id, this.type);
}

enum CollectionMetaEventType {
  created,
  deleted,
  archived,
  sortChanged,
  orderChanged,
  thumbnailChanged,
  autoAddPeople,
}
