import "package:photos/events/event.dart";

class LocalAssetChangedEvent extends Event {
  final String source;

  LocalAssetChangedEvent(this.source);

  @override
  String get reason => '$runtimeType{"via": $source}';
}
