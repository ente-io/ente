import "dart:collection";

import "package:ente_events/models/event.dart";
import "package:locker/services/files/upload/models/backup_item.dart";

class BackupUpdatedEvent extends Event {
  final LinkedHashMap<String, BackupItem> items;

  BackupUpdatedEvent(this.items);
}
