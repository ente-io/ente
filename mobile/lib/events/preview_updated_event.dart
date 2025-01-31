import "dart:collection";

import "package:photos/events/event.dart";
import "package:photos/models/preview/preview_item.dart";

class PreviewUpdatedEvent extends Event {
  final LinkedHashMap<int, PreviewItem> items;

  PreviewUpdatedEvent(this.items);
}
