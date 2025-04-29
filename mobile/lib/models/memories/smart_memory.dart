import "package:photos/generated/l10n.dart";
import "package:photos/models/memories/memory.dart";

enum MemoryType {
  people,
  trips,
  clip,
  time,
  filler,
}

MemoryType memoryTypeFromString(String type) {
  switch (type) {
    case "people":
      return MemoryType.people;
    case "trips":
      return MemoryType.trips;
    case "time":
      return MemoryType.time;
    case "filler":
      return MemoryType.filler;
    case "clip":
      return MemoryType.clip;
    default:
      throw ArgumentError("Invalid memory type: $type");
  }
}

class SmartMemory {
  final List<Memory> memories;
  final MemoryType type;
  String title;
  int firstDateToShow;
  int lastDateToShow;

  int? firstCreationTime;
  int? lastCreationTime;

  SmartMemory(
    this.memories,
    this.type,
    this.title,
    this.firstDateToShow,
    this.lastDateToShow, {
    this.firstCreationTime,
    this.lastCreationTime,
  });

  bool get notForShow => firstDateToShow == 0 && lastDateToShow == 0;

  bool isOld() {
    return lastDateToShow < DateTime.now().microsecondsSinceEpoch;
  }

  bool shouldShowNow() {
    final int now = DateTime.now().microsecondsSinceEpoch;
    return now >= firstDateToShow && now <= lastDateToShow;
  }

  String createTitle(S s, String languageCode) {
    throw UnimplementedError("createTitle must be implemented in subclass");
  }

  int averageCreationTime() {
    if (firstCreationTime != null && lastCreationTime != null) {
      return (firstCreationTime! + lastCreationTime!) ~/ 2;
    }
    final List<int> creationTimes = memories
        .where((memory) => memory.file.creationTime != null)
        .map((memory) => memory.file.creationTime!)
        .toList();
    if (creationTimes.length < 2) {
      if (creationTimes.isEmpty) {
        firstCreationTime = 0;
        lastCreationTime = 0;
        return 0;
      }
      return creationTimes.isEmpty ? 0 : creationTimes.first;
    }
    creationTimes.sort();
    firstCreationTime ??= creationTimes.first;
    lastCreationTime ??= creationTimes.last;
    return (firstCreationTime! + lastCreationTime!) ~/ 2;
  }
}
