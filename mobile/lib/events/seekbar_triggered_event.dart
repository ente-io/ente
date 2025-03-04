import "package:photos/events/event.dart";

class SeekbarTriggeredEvent extends Event {
  final int position;

  SeekbarTriggeredEvent({required this.position});
}
