import 'package:ente_events/models/event.dart';

class CollectionsUpdatedEvent extends Event {
  CollectionsUpdatedEvent(this.source);

  final String source;
}
