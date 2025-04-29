import "package:photos/events/event.dart";

class MachineLearningControlEvent extends Event {
  final bool shouldRun;

  MachineLearningControlEvent(this.shouldRun);
}
