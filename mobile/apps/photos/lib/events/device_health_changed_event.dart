import "package:photos/events/event.dart";

class DeviceHealthChangedEvent extends Event {
  final bool isHealthy;

  DeviceHealthChangedEvent(this.isHealthy);
}
