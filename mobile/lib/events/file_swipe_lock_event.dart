import "package:photos/events/event.dart";

class FileSwipeLockEvent extends Event {
  final bool isGuestView;
  final bool swipeLocked;
  FileSwipeLockEvent(this.isGuestView, this.swipeLocked);
}
