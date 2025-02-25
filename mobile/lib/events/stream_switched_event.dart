import "package:photos/events/event.dart";

class StreamSwitchedEvent extends Event {
  final bool selectedPreview;
  final PlayerType type;

  StreamSwitchedEvent(this.selectedPreview, this.type);
}

enum PlayerType { mediaKit, nativeVideoPlayer }
