import "dart:collection";

import "package:photos/events/event.dart";
import "package:photos/models/backup/backup_item.dart";

class BackupUpdatedEvent extends Event {
  final LinkedHashMap<String, BackupItem> items;

  BackupUpdatedEvent(this.items);
}
