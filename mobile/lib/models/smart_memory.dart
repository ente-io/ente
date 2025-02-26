import "package:photos/models/memory.dart";

enum MemoryType {
  people,
  trips,
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
    default:
      throw ArgumentError("Invalid memory type: $type");
  }
}

class SmartMemory {
  final List<Memory> memories;
  final MemoryType type;
  String name;
  int? firstCreationTime;
  int? lastCreationTime;

  int? firstDateToShow;
  int? lastDateToShow;
  // TODO: lau: make the above two non-nullable!!!
  // TODO: lau: actually use this in calculated filters

  SmartMemory(
    this.memories,
    this.type, {
    name,
    this.firstCreationTime,
    this.lastCreationTime,
    this.firstDateToShow,
    this.lastDateToShow,
  }) : name = name != null ? name + "(I)" : null;
  // TODO: lau: remove (I) from name when opening up the feature flag

  bool isOld() {
    if (firstDateToShow == null || lastDateToShow == null) {
      return false;
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    return lastDateToShow! < now;
  }
  
  bool hasShowTime() {
    return firstDateToShow != null && lastDateToShow != null;
  }

  bool shouldShowNow() {
    if (!hasShowTime()) {
      return false;
    }
    final int now = DateTime.now().microsecondsSinceEpoch;
    return now >= firstDateToShow! && now <= lastDateToShow!;
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
      return creationTimes.isEmpty ? 0 : creationTimes.first;
    }
    creationTimes.sort();
    firstCreationTime ??= creationTimes.first;
    lastCreationTime ??= creationTimes.last;
    return (firstCreationTime! + lastCreationTime!) ~/ 2;
  }
}
