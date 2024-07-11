import "package:photos/events/event.dart";

enum AppLockUpdateType {
  none,
  device,
  pin,
  password,
}

class AppLockUpdateEvent extends Event {
  final AppLockUpdateType type;

  AppLockUpdateEvent(this.type);
}
