import "package:photos/models/memory.dart";

enum MemoryType {
  people,
  trips,
  time,
  filler,
}

abstract class SmartMemory {
  final List<Memory> memories;
  final MemoryType type;
  String? name;
  int? firstCreationTime;
  int? lastCreationTime;

  SmartMemory(
    this.memories,
    this.type, {
    name,
    this.firstCreationTime,
    this.lastCreationTime,
  }) : name = name != null ? name + "(I)" : null;

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
