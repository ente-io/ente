import "package:photos/events/event.dart";

class FileSwipeLockEvent extends Event {
  final bool shouldSwipeLock;

  FileSwipeLockEvent(this.shouldSwipeLock);
}
