import "package:photos/models/memory.dart";
import "package:photos/models/smart_memory.dart";

class TimeMemory extends SmartMemory {
  TimeMemory(
    List<Memory> memories, {
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
    int? firstDateToShow,
    int? lastDateToShow,
  }) : super(
          memories,
          MemoryType.time,
          name: name,
          firstCreationTime: firstCreationTime,
          lastCreationTime: lastCreationTime,
          firstDateToShow: firstDateToShow,
          lastDateToShow: lastDateToShow,
        );

  @override
  TimeMemory copyWith({
    List<Memory>? memories,
    String? name,
    int? firstCreationTime,
    int? lastCreationTime,
    int? firstDateToShow,
    int? lastDateToShow,
  }) {
    return TimeMemory(
      memories ?? this.memories,
      name: name ?? this.name,
      firstCreationTime: firstCreationTime ?? super.firstCreationTime,
      lastCreationTime: lastCreationTime ?? super.lastCreationTime,
      firstDateToShow: firstDateToShow ?? super.firstDateToShow,
      lastDateToShow: lastDateToShow ?? super.lastDateToShow,
    );
  }
}
