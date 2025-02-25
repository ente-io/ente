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

abstract class SmartMemory {
  final List<Memory> memories;
  final MemoryType type;
  String? name;
  int? firstCreationTime;
  int? lastCreationTime;

  int? firstDateToShow;
  int? lastDateToShow;
  // TODO: lau: actually use this in calculated filters


  SmartMemory(
    this.memories,
    this.type, {
    name,
    this.firstCreationTime,
    this.lastCreationTime,
  }) : name = name != null ? name + "(I)" : null;
  // TODO: lau: remove (I) from name when opening up the feature flag

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

  SmartMemory copyWith({
    List<Memory>? memories,
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
  });
}
