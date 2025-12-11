import "package:photos/events/event.dart";
import "package:photos/models/memory_lane/memory_lane_models.dart";

class FacesTimelineChangedEvent extends Event {
  final String personId;
  final FacesTimelineStatus status;

  FacesTimelineChangedEvent({
    required this.personId,
    required this.status,
  });

  bool get isReady => status == FacesTimelineStatus.ready;

  @override
  String get reason =>
      '$runtimeType{personId: $personId, status: ${status.name}}';
}
