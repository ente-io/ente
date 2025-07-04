import "package:photos/events/event.dart";

class GuestViewEvent extends Event {
  final bool isGuestView;
  final bool swipeLocked;
  GuestViewEvent(this.isGuestView, this.swipeLocked);
}
