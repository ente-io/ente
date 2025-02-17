import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

class TimeMemory extends SmartMemory {
  TimeMemory(
    List<Memory> memories, {
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
  }) : super(
          memories,
          MemoryType.time,
          name: name,
          firstCreationTime: firstCreationTime,
          lastCreationTime: lastCreationTime,
        );

  @override
  TimeMemory copyWith({
    List<Memory>? memories,
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
  }) {
    return TimeMemory(
      memories ?? this.memories,
      name: name ?? this.name,
      firstCreationTime: firstCreationTime ?? super.firstCreationTime,
      lastCreationTime: lastCreationTime ?? super.lastCreationTime,
    );
  }
}
