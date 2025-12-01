import "package:photos/events/event.dart";

class SwipeToSelectEnabledEvent extends Event {
  final bool isEnabled;

  SwipeToSelectEnabledEvent(this.isEnabled);
}
