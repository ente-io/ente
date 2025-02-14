import "package:photos/models/file/file.dart";

enum MemoryType {
  people,
  trips,
  time,
  filler,
}

abstract class SmartMemory {
  final List<EnteFile> files;
  final MemoryType type;
  int? firstCreationTime;
  int? lastCreationTime;

  SmartMemory(
    this.files,
    this.type, {
    this.firstCreationTime,
    this.lastCreationTime,
  });

  int averageCreationTime() {
    if (firstCreationTime != null && lastCreationTime != null) {
      return (firstCreationTime! + lastCreationTime!) ~/ 2;
    }
    final List<int> creationTimes = files
        .where((file) => file.creationTime != null)
        .map((file) => file.creationTime!)
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
    List<EnteFile>? files,
    int? firstCreationTime,
    int? lastCreationTime,
  });
}
