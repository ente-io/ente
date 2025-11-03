import "package:photos/events/event.dart";
import "package:photos/models/faces_timeline/faces_timeline_models.dart";

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
