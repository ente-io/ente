import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

class TimeMemory extends SmartMemory {
  TimeMemory(
    List<Memory> memories,
    String title,
    int firstDateToShow,
    int lastDateToShow, {
    int? firstCreationTime,
    int? lastCreationTime,
  }) : super(
          memories,
          MemoryType.time,
          title,
          firstDateToShow,
          lastDateToShow,
        );
}
