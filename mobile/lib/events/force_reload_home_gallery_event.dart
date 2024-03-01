import 'package:photos/events/event.dart';

class ForceReloadHomeGalleryEvent extends Event {
  final String message;

  ForceReloadHomeGalleryEvent(this.message);

  @override
  String get reason => '$runtimeType - $message';
}
