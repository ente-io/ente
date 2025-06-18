import "package:photos/events/event.dart";

class ComputeControlEvent extends Event {
  final bool shouldRun;

  ComputeControlEvent(this.shouldRun);
}
