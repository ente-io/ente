import 'package:photos/events/event.dart';

class LocalImportProgressEvent extends Event {
  final String folderName;
  final int count;

  LocalImportProgressEvent(this.folderName, this.count);
}
