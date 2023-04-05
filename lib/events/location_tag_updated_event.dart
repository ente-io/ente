import 'package:photos/events/event.dart';

class LocationTagUpdatedEvent extends Event {
  final List<String>? updatedLocationTagIds;
  final LocTagEventType type;

  LocationTagUpdatedEvent(this.type, {this.updatedLocationTagIds});
}

enum LocTagEventType {
  add,
  update,
  delete,
}
