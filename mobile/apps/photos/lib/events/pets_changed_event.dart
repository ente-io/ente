import "package:photos/events/event.dart";

class PetsChangedEvent extends Event {
  final String source;

  PetsChangedEvent({this.source = ""});

  @override
  String get reason => '$runtimeType{"via": $source}';
}
